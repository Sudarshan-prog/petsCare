/**
 * CAREBRIDGE — CLOUD FUNCTIONS (Phase 1)
 * ======================================
 * 5 Cloud Functions that make the app production-ready:
 *
 * 1. createBooking     — Server-side price validation + booking creation
 * 2. updateBookingStatus — State machine enforcement + payment ops + notifications
 * 3. submitRating      — Verified rating with duplicate prevention
 * 4. deleteAccount     — GDPR/App Store compliant data cleanup
 * 5. razorpayWebhook   — Server-side payment event handler
 *
 * Fee Model: 5% split (2.5% from owner + 2.5% from caretaker)
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getAuth } = require("firebase-admin/auth");
const { getStorage } = require("firebase-admin/storage");
const crypto = require("crypto");

// Initialize Firebase Admin
const app = initializeApp();
const db = getFirestore(app);
const messaging = getMessaging(app);
const auth = getAuth(app);
const storage = getStorage(app);

// ============================================================
// CONSTANTS
// ============================================================
const OWNER_FEE_PERCENT = 0.025;       // 2.5% charged to owner
const CARETAKER_COMMISSION = 0.025;     // 2.5% deducted from caretaker
const VALID_STATUSES = ["pending", "confirmed", "completed", "cancelled"];
const VALID_TRANSITIONS = {
  pending: ["confirmed", "cancelled"],
  confirmed: ["completed", "cancelled"],
  completed: [],   // Terminal state
  cancelled: [],   // Terminal state
};

// Who can trigger each transition
const TRANSITION_ROLES = {
  "pending->confirmed": "caretaker",
  "pending->cancelled": "both",
  "confirmed->completed": "owner",
  "confirmed->cancelled": "both",
};

// ============================================================
// HELPER: Send FCM Push Notification
// ============================================================
async function sendNotification(userId, title, body, data = {}) {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}`);
      return;
    }

    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      data: { ...data, click_action: "FLUTTER_NOTIFICATION_CLICK" },
      android: {
        priority: "high",
        notification: {
          channelId: "carebridge_bookings",
          sound: "default",
        },
      },
    });
    console.log(`✅ Notification sent to ${userId}: ${title}`);
  } catch (error) {
    // Don't fail the function if notification fails
    console.error(`⚠️ Notification failed for ${userId}:`, error.message);
  }
}

// ============================================================
// CLOUD FUNCTION 1: createBooking
// ============================================================
exports.createBooking = onCall(async (request) => {
  // Auth check
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in to create a booking.");
  }

  const uid = request.auth.uid;
  const {
    caretakerId,
    petId,
    petName,
    services,
    hours,
    date,
    timeSlot,
    notes,
    paymentId,
  } = request.data;

  // ---- Input Validation ----
  if (!caretakerId || !petId || !date || !timeSlot || !hours) {
    throw new HttpsError("invalid-argument", "Missing required fields: caretakerId, petId, date, timeSlot, hours");
  }

  if (!Array.isArray(services) || services.length === 0) {
    throw new HttpsError("invalid-argument", "At least one service must be selected.");
  }

  if (typeof hours !== "number" || hours < 1 || hours > 24) {
    throw new HttpsError("invalid-argument", "Hours must be between 1 and 24.");
  }

  // ---- Fetch caretaker's REAL price from Firestore ----
  const caretakerDoc = await db.collection("caretakers").doc(caretakerId).get();
  if (!caretakerDoc.exists) {
    throw new HttpsError("not-found", "Caretaker not found.");
  }
  const caretaker = caretakerDoc.data();

  // ---- Fetch owner's data ----
  const ownerDoc = await db.collection("users").doc(uid).get();
  if (!ownerDoc.exists) {
    throw new HttpsError("not-found", "Owner user not found.");
  }
  const owner = ownerDoc.data();

  // ---- Server-Side Price Calculation (THE KEY SECURITY FIX) ----
  const baseRate = caretaker.price || 0;
  const serviceFees = caretaker.serviceFees || {};

  let servicePrice = baseRate * hours;
  let totalPremiums = 0;
  for (const service of services) {
    totalPremiums += serviceFees[service] || 0;
  }

  const basePrice = servicePrice + totalPremiums;
  const ownerFee = Math.round(basePrice * OWNER_FEE_PERCENT * 100) / 100;
  const caretakerCommission = Math.round(basePrice * CARETAKER_COMMISSION * 100) / 100;
  const totalPrice = Math.round((basePrice + ownerFee) * 100) / 100;
  const caretakerPayout = Math.round((basePrice - caretakerCommission) * 100) / 100;

  // ---- Check for Booking Overlap ----
  const existingBookings = await db
    .collection("bookings")
    .where("caretakerId", "==", caretakerId)
    .where("date", "==", date)
    .where("timeSlot", "==", timeSlot)
    .where("status", "in", ["pending", "confirmed"])
    .get();

  if (!existingBookings.empty) {
    throw new HttpsError(
      "already-exists",
      "This caretaker already has a booking at this time."
    );
  }

  // ---- Create Booking Document ----
  const bookingData = {
    caretakerId,
    caretakerName: caretaker.name || "",
    ownerId: uid,
    ownerName: owner.name || "",
    petId,
    petName: petName || "",
    date,
    timeSlot,
    services,
    hours,
    basePrice,
    ownerFee,
    caretakerCommission,
    totalPrice,
    caretakerPayout,
    status: "pending",
    paymentStatus: paymentId ? "authorized" : "unpaid",
    paymentId: paymentId || null,
    notes: notes || null,
    statusImageUrl: null,
    isRated: false,
    createdAt: FieldValue.serverTimestamp(),
  };

  const bookingRef = await db.collection("bookings").add(bookingData);

  // ---- Send Notification to Caretaker ----
  await sendNotification(
    caretakerId,
    "🐾 New Booking Request!",
    `${owner.name || "A pet parent"} wants to book you for ${services.join(", ")}`,
    { bookingId: bookingRef.id, type: "new_booking" }
  );

  console.log(`✅ Booking ${bookingRef.id} created. Total: ₹${totalPrice}, Caretaker gets: ₹${caretakerPayout}`);

  return {
    success: true,
    bookingId: bookingRef.id,
    totalPrice,
    caretakerPayout,
    ownerFee,
  };
});

// ============================================================
// CLOUD FUNCTION 2: updateBookingStatus
// ============================================================
exports.updateBookingStatus = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const uid = request.auth.uid;
  const { bookingId, newStatus } = request.data;

  if (!bookingId || !newStatus) {
    throw new HttpsError("invalid-argument", "bookingId and newStatus are required.");
  }

  if (!VALID_STATUSES.includes(newStatus)) {
    throw new HttpsError("invalid-argument", `Invalid status: ${newStatus}`);
  }

  // ---- Fetch Booking ----
  const bookingRef = db.collection("bookings").doc(bookingId);
  const bookingDoc = await bookingRef.get();

  if (!bookingDoc.exists) {
    throw new HttpsError("not-found", "Booking not found.");
  }

  const booking = bookingDoc.data();
  const currentStatus = booking.status;

  // ---- Validate State Transition ----
  const allowedTransitions = VALID_TRANSITIONS[currentStatus] || [];
  if (!allowedTransitions.includes(newStatus)) {
    throw new HttpsError(
      "failed-precondition",
      `Cannot transition from '${currentStatus}' to '${newStatus}'.`
    );
  }

  // ---- Validate Role ----
  const transitionKey = `${currentStatus}->${newStatus}`;
  const requiredRole = TRANSITION_ROLES[transitionKey];

  const isOwner = uid === booking.ownerId;
  const isCaretaker = uid === booking.caretakerId;

  if (!isOwner && !isCaretaker) {
    throw new HttpsError("permission-denied", "You are not part of this booking.");
  }

  if (requiredRole === "owner" && !isOwner) {
    throw new HttpsError("permission-denied", "Only the pet owner can perform this action.");
  }
  if (requiredRole === "caretaker" && !isCaretaker) {
    throw new HttpsError("permission-denied", "Only the caretaker can perform this action.");
  }

  // ---- Build Update Object ----
  const updateData = {
    status: newStatus,
  };

  // ---- Handle Payment Operations Based on Transition ----
  // NOTE: Full Razorpay server-side capture requires API Key + Secret.
  //       For now, we update status and log the intent.
  //       When you add Razorpay credentials, uncomment the API calls below.

  if (newStatus === "confirmed" && booking.paymentStatus === "authorized") {
    // Caretaker accepted → Capture the authorized payment
    updateData.paymentStatus = "paid";
    console.log(`💰 Payment capture needed for booking ${bookingId}, paymentId: ${booking.paymentId}`);

    // TODO: Uncomment when Razorpay API secret is configured
    // const Razorpay = require("razorpay");
    // const rzp = new Razorpay({ key_id: process.env.RAZORPAY_KEY, key_secret: process.env.RAZORPAY_SECRET });
    // await rzp.payments.capture(booking.paymentId, booking.totalPrice * 100, "INR");
  }

  if (newStatus === "cancelled" && booking.paymentStatus === "authorized") {
    // Cancelled before acceptance → Release authorization
    updateData.paymentStatus = "released";
    console.log(`🛡️ Payment release needed for booking ${bookingId}`);
  }

  if (newStatus === "cancelled" && booking.paymentStatus === "paid") {
    // Cancelled after acceptance → Refund
    updateData.paymentStatus = "refunded";
    console.log(`⚠️ Refund needed for booking ${bookingId}`);

    // TODO: Uncomment when Razorpay API secret is configured
    // const Razorpay = require("razorpay");
    // const rzp = new Razorpay({ key_id: process.env.RAZORPAY_KEY, key_secret: process.env.RAZORPAY_SECRET });
    // await rzp.payments.refund(booking.paymentId, { amount: booking.totalPrice * 100 });
  }

  if (newStatus === "completed" || newStatus === "cancelled") {
    // Purge status photo when booking ends
    if (booking.statusImageUrl) {
      updateData.statusImageUrl = null;
      // Try to delete from Storage
      try {
        const bucket = storage.bucket();
        const filePath = `bookings/${bookingId}`;
        await bucket.deleteFiles({ prefix: filePath });
        console.log(`🧹 Purged photos for booking ${bookingId}`);
      } catch (err) {
        console.error(`⚠️ Photo purge failed:`, err.message);
      }
    }
  }

  // ---- Apply Update ----
  await bookingRef.update(updateData);

  // ---- Send Notification ----
  const notifyUserId = isOwner ? booking.caretakerId : booking.ownerId;
  const notifierName = isOwner ? booking.ownerName : booking.caretakerName;

  const notificationMap = {
    confirmed: {
      title: "✅ Booking Confirmed!",
      body: `${notifierName} accepted the booking.`,
    },
    completed: {
      title: "🎉 Booking Completed!",
      body: `Your session with ${notifierName} is complete. Leave a rating!`,
    },
    cancelled: {
      title: "❌ Booking Cancelled",
      body: `${notifierName} cancelled the booking.`,
    },
  };

  const notification = notificationMap[newStatus];
  if (notification) {
    await sendNotification(
      notifyUserId,
      notification.title,
      notification.body,
      { bookingId, type: `booking_${newStatus}` }
    );
  }

  console.log(`✅ Booking ${bookingId}: ${currentStatus} → ${newStatus} by ${isOwner ? "owner" : "caretaker"}`);

  return { success: true, bookingId, newStatus };
});

// ============================================================
// CLOUD FUNCTION 3: submitRating
// ============================================================
exports.submitRating = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const uid = request.auth.uid;
  const { bookingId, rating } = request.data;

  if (!bookingId || rating === undefined) {
    throw new HttpsError("invalid-argument", "bookingId and rating are required.");
  }

  // ---- Validate Rating Range ----
  if (typeof rating !== "number" || rating < 1.0 || rating > 5.0) {
    throw new HttpsError("invalid-argument", "Rating must be a number between 1.0 and 5.0.");
  }

  // ---- Fetch Booking ----
  const bookingRef = db.collection("bookings").doc(bookingId);
  const bookingDoc = await bookingRef.get();

  if (!bookingDoc.exists) {
    throw new HttpsError("not-found", "Booking not found.");
  }

  const booking = bookingDoc.data();

  // ---- Validate: Caller must be the owner of this booking ----
  if (uid !== booking.ownerId) {
    throw new HttpsError("permission-denied", "Only the pet owner can rate this booking.");
  }

  // ---- Validate: Booking must be completed ----
  if (booking.status !== "completed") {
    throw new HttpsError("failed-precondition", "Can only rate completed bookings.");
  }

  // ---- Validate: Not already rated ----
  if (booking.isRated === true) {
    throw new HttpsError("already-exists", "This booking has already been rated.");
  }

  // ---- Update Caretaker Rating (Running Average) ----
  const caretakerRef = db.collection("caretakers").doc(booking.caretakerId);

  await db.runTransaction(async (transaction) => {
    const caretakerDoc = await transaction.get(caretakerRef);
    if (!caretakerDoc.exists) {
      throw new HttpsError("not-found", "Caretaker not found.");
    }

    const caretaker = caretakerDoc.data();
    const currentRating = caretaker.rating || 0;
    const currentCount = caretaker.reviewCount || 0;

    // Calculate new running average
    const newCount = currentCount + 1;
    const newRating = ((currentRating * currentCount) + rating) / newCount;
    const roundedRating = Math.round(newRating * 10) / 10; // Round to 1 decimal

    transaction.update(caretakerRef, {
      rating: roundedRating,
      reviewCount: newCount,
    });

    // Mark booking as rated
    transaction.update(bookingRef, { isRated: true });
  });

  // Notify caretaker
  await sendNotification(
    booking.caretakerId,
    "⭐ New Rating Received!",
    `${booking.ownerName} rated you ${rating.toFixed(1)} stars.`,
    { bookingId, type: "rating_received" }
  );

  console.log(`✅ Rating ${rating} for caretaker ${booking.caretakerId} on booking ${bookingId}`);

  return { success: true, rating };
});

// ============================================================
// CLOUD FUNCTION 4: deleteAccount
// ============================================================
exports.deleteAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const uid = request.auth.uid;

  console.log(`🗑️ Starting account deletion for user ${uid}`);

  try {
    // ---- 1. Cancel all pending bookings ----
    const pendingBookings = await db
      .collection("bookings")
      .where("ownerId", "==", uid)
      .where("status", "in", ["pending", "confirmed"])
      .get();

    const batch1 = db.batch();
    pendingBookings.docs.forEach((doc) => {
      batch1.update(doc.ref, {
        status: "cancelled",
        paymentStatus: doc.data().paymentStatus === "authorized" ? "released" : doc.data().paymentStatus,
      });
    });
    await batch1.commit();
    console.log(`  Cancelled ${pendingBookings.size} pending bookings`);

    // Also cancel bookings where user is caretaker
    const caretakerBookings = await db
      .collection("bookings")
      .where("caretakerId", "==", uid)
      .where("status", "in", ["pending", "confirmed"])
      .get();

    const batch2 = db.batch();
    caretakerBookings.docs.forEach((doc) => {
      batch2.update(doc.ref, {
        status: "cancelled",
        paymentStatus: doc.data().paymentStatus === "paid" ? "refunded" : doc.data().paymentStatus,
      });
    });
    await batch2.commit();
    console.log(`  Cancelled ${caretakerBookings.size} caretaker bookings`);

    // ---- 2. Delete user's pets ----
    const pets = await db.collection("pets").where("ownerId", "==", uid).get();
    const batch3 = db.batch();
    pets.docs.forEach((doc) => batch3.delete(doc.ref));
    await batch3.commit();
    console.log(`  Deleted ${pets.size} pets`);

    // ---- 3. Delete caretaker profile (if exists) ----
    const caretakerDoc = await db.collection("caretakers").doc(uid).get();
    if (caretakerDoc.exists) {
      await caretakerDoc.ref.delete();
      console.log("  Deleted caretaker profile");
    }

    // ---- 4. Delete profile photos from Storage ----
    try {
      const bucket = storage.bucket();
      await bucket.deleteFiles({ prefix: `users/${uid}` });
      await bucket.deleteFiles({ prefix: `caretakers/${uid}` });
      console.log("  Cleaned up Storage files");
    } catch (err) {
      console.error("  Storage cleanup failed (non-fatal):", err.message);
    }

    // ---- 5. Delete user document ----
    await db.collection("users").doc(uid).delete();
    console.log("  Deleted user document");

    // ---- 6. Delete Firebase Auth account ----
    await auth.deleteUser(uid);
    console.log("  Deleted Auth account");

    console.log(`✅ Account deletion complete for ${uid}`);
    return { success: true };
  } catch (error) {
    console.error(`❌ Account deletion failed for ${uid}:`, error);
    throw new HttpsError("internal", "Account deletion failed. Please contact support.");
  }
});

// ============================================================
// CLOUD FUNCTION 5: Razorpay Webhook Handler
// ============================================================
exports.razorpayWebhook = onRequest(async (req, res) => {
  // Only accept POST requests
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;

    // ---- Verify Webhook Signature (if secret is configured) ----
    if (webhookSecret) {
      const signature = req.headers["x-razorpay-signature"];
      const expectedSignature = crypto
        .createHmac("sha256", webhookSecret)
        .update(JSON.stringify(req.body))
        .digest("hex");

      if (signature !== expectedSignature) {
        console.error("❌ Invalid webhook signature");
        res.status(400).send("Invalid signature");
        return;
      }
    } else {
      console.warn("⚠️ RAZORPAY_WEBHOOK_SECRET not set. Skipping signature verification.");
    }

    const event = req.body.event;
    const payload = req.body.payload;

    console.log(`📨 Razorpay webhook: ${event}`);

    if (!payload || !payload.payment || !payload.payment.entity) {
      res.status(200).send("No payment data in webhook");
      return;
    }

    const payment = payload.payment.entity;
    const paymentId = payment.id;

    // Find the booking with this payment ID
    const bookingsQuery = await db
      .collection("bookings")
      .where("paymentId", "==", paymentId)
      .limit(1)
      .get();

    if (bookingsQuery.empty) {
      console.log(`⚠️ No booking found for payment ${paymentId}`);
      res.status(200).send("OK - No matching booking");
      return;
    }

    const bookingDoc = bookingsQuery.docs[0];
    const bookingRef = bookingDoc.ref;

    // ---- Handle Different Payment Events ----
    switch (event) {
      case "payment.authorized":
        await bookingRef.update({ paymentStatus: "authorized" });
        console.log(`✅ Payment ${paymentId} authorized`);
        break;

      case "payment.captured":
        await bookingRef.update({ paymentStatus: "paid" });
        console.log(`✅ Payment ${paymentId} captured`);
        break;

      case "payment.failed":
        await bookingRef.update({
          paymentStatus: "failed",
          status: "cancelled",
        });
        console.log(`❌ Payment ${paymentId} failed — booking cancelled`);

        // Notify owner
        const failedBooking = bookingDoc.data();
        await sendNotification(
          failedBooking.ownerId,
          "❌ Payment Failed",
          "Your payment could not be processed. The booking has been cancelled.",
          { bookingId: bookingDoc.id, type: "payment_failed" }
        );
        break;

      case "refund.processed":
        await bookingRef.update({ paymentStatus: "refunded" });
        console.log(`🔄 Refund processed for payment ${paymentId}`);

        const refundedBooking = bookingDoc.data();
        await sendNotification(
          refundedBooking.ownerId,
          "💰 Refund Processed",
          `Your refund of ₹${refundedBooking.totalPrice} has been processed.`,
          { bookingId: bookingDoc.id, type: "refund_processed" }
        );
        break;

      default:
        console.log(`ℹ️ Unhandled event: ${event}`);
    }

    res.status(200).send("OK");
  } catch (error) {
    console.error("❌ Webhook error:", error);
    res.status(500).send("Internal Server Error");
  }
});

/**
 * CareBridge Maintenance Tool (Method 2)
 * 
 * This script allows you to perform powerful admin actions that the Firebase Console
 * doesn't support, like bulk-deleting users.
 * 
 * SETUP:
 * 1. Go to Firebase Console -> Project Settings -> Service Accounts.
 * 2. Click "Generate New Private Key" and download the JSON file.
 * 3. Rename it to 'service-account.json' and place it in the same folder as this script.
 * 4. Run: npm install firebase-admin
 * 5. Run: node maintenance_tool.js
 */

const admin = require('firebase-admin');
const path = require('path');

// 1. Initialize admin with service account
const serviceAccountPath = path.join(__dirname, 'service-account.json');

try {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log('✅ Firebase Admin initialized successfully.');
} catch (error) {
    console.error('❌ ERROR: Could not find service-account.json.');
    console.log('Please download it from Firebase Console and place it in: ' + serviceAccountPath);
    process.exit(1);
}

const auth = admin.auth();
const db = admin.firestore();

/**
 * Nukes All Firestore Collections
 */
async function deleteCollection(collectionPath, batchSize = 100) {
    const collectionRef = db.collection(collectionPath);
    const query = collectionRef.orderBy('__name__').limit(batchSize);

    return new Promise((resolve, reject) => {
        deleteQueryBatch(query, resolve).catch(reject);
    });
}

async function deleteQueryBatch(query, resolve) {
    const snapshot = await query.get();

    const batchSize = snapshot.size;
    if (batchSize === 0) {
        resolve();
        return;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
    });
    await batch.commit();

    process.nextTick(() => {
        deleteQueryBatch(query, resolve);
    });
}

async function nukeDatabase() {
    console.log('\n--- ☢️ STARTING NUCLEAR PURGE ☢️ ---');

    // 1. Delete Auth Users
    let totalDeleted = 0;
    async function processAuthBatch(nextPageToken) {
        const result = await auth.listUsers(1000, nextPageToken);
        const uids = result.users.map(user => user.uid);
        if (uids.length > 0) {
            await auth.deleteUsers(uids);
            console.log(`🗑️ Auth: Deleted ${uids.length} users.`);
            totalDeleted += uids.length;
        }
        if (result.pageToken) await processAuthBatch(result.pageToken);
    }

    try {
        await processAuthBatch();

        // 2. Delete Firestore Collections
        const collections = ['users', 'caretakers', 'pets', 'bookings'];
        for (const col of collections) {
            console.log(`🧹 Firestore: Wiping collection '${col}'...`);
            await deleteCollection(col);
        }

        console.log(`\n✨ PROJECT IS NOW CLEAN.`);
        console.log(`Total Auth Users Purged: ${totalDeleted}`);
        console.log(`Collections Wiped: ${collections.join(', ')}`);
        console.log('--- Ready for Demo ---');
    } catch (error) {
        console.error('❌ ERROR during purge:', error);
    }
}

// EXECUTE
nukeDatabase();

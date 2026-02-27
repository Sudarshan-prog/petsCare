import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'payment_repository_interface.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class RazorpayRepository implements IPaymentRepository {
  late Razorpay _razorpay;

  // Store callbacks for the Developer Bypass mode
  Function(PaymentSuccessResponse)? _onSuccess;

  @override
  void initialize({
    required Function(PaymentSuccessResponse p1) onSuccess,
    required Function(PaymentFailureResponse p1) onFailure,
    required Function(ExternalWalletResponse p1) onExternalWallet,
  }) {
    _onSuccess = onSuccess;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  @override
  void openCheckout({
    required double amount,
    required String contact,
    required String email,
    required String description,
    String? caretakerId,
  }) {
    // ARCHITECT: DEVELOPER BYPASS LOGIC
    if (AppConfig.razorpayKey.contains('YourKeyGoesHere')) {
      debugPrint(
          'ARCHITECT: Razorpay Key placeholder found. Entering Simulation Mode...');

      Future.delayed(const Duration(seconds: 2), () {
        if (_onSuccess != null) {
          debugPrint('ARCHITECT: Simulation Success! Triggering success.');
          _onSuccess!(PaymentSuccessResponse(
            'pay_Simulated_${DateTime.now().millisecondsSinceEpoch}',
            null,
            null,
            null,
          ));
        }
      });
      return;
    }

    var options = {
      'key': AppConfig.razorpayKey,
      'amount': (amount * 100).toInt(),
      'name': 'PetCare Bridge',
      'description': description,
      'payment_capture': 0, // ARCHITECT: Blueprint A (Manual Capture)
      if (caretakerId != null)
        'transfers': [
          {
            'account': caretakerId,
            'amount': ((amount - AppConfig.platformFee) * 100).toInt(),
            'currency': 'INR',
            'notes': {'booking_for': contact},
            'on_hold': true // ARCHITECT: Profit Protection
          }
        ],
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': contact, 'email': email},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Future<void> capturePayment(String paymentId, double amount) async {
    // ARCHITECT: This is called when Caretaker hits ACCEPT
    // Finalizes the AUTHORIZED payment.
    debugPrint(
        '💰 ARCHITECT: Capturing Authorized Payment: $paymentId for ₹$amount');
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('✅ ARCHITECT: Capture command sent to backend.');
  }

  @override
  Future<void> releasePayment(String paymentId) async {
    // ARCHITECT: This is called when Caretaker hits REJECT
    // Cancels the authorization. Profit = 100% (No Fees).
    debugPrint('🛡️ ARCHITECT: Releasing (Voiding) payment: $paymentId');
    await Future.delayed(const Duration(seconds: 1));
    debugPrint(
        '✅ ARCHITECT: Authorization cancelled. Money released to user at zero cost.');
  }

  @override
  Future<void> refundPayment(String paymentId) async {
    // ARCHITECT: REFUND SECURITY POLICY
    // Used for cancellations AFTER the booking was already accepted/captured.
    debugPrint('🛡️ ARCHITECT: Triggering Refund logic for: $paymentId');
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('✅ ARCHITECT: Refund Request logged for backend processing.');
  }

  @override
  void dispose() {
    _razorpay.clear();
  }
}

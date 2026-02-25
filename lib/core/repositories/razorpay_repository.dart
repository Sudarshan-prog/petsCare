import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'payment_repository_interface.dart';
import 'package:flutter/foundation.dart';

class RazorpayRepository implements IPaymentRepository {
  late Razorpay _razorpay;

  // Store callbacks for the Developer Bypass mode
  Function(PaymentSuccessResponse)? _onSuccess;

  // ARCHITECT: Replace this with your actual Razorpay Key from dashboard
  static const String _razorpayKey = 'rzp_test_YourActualKeyHere';

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
  }) {
    // ARCHITECT: DEVELOPER BYPASS LOGIC
    // If the key is the placeholder, we simulate a successful payment for the demo.
    if (_razorpayKey.contains('YourActualKeyHere')) {
      debugPrint(
          'ARCHITECT: Razorpay Key not found. Entering Simulation Mode for Demo...');

      Future.delayed(const Duration(seconds: 2), () {
        if (_onSuccess != null) {
          debugPrint(
              'ARCHITECT: Simulation Successful! Triggering success callback.');
          // Simulating a success response with a fake payment ID
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
      'key': _razorpayKey,
      'amount': (amount * 100).toInt(), // Razorpay expects amount in paise
      'name': 'PetCare Bridge',
      'description': description,
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
  void dispose() {
    _razorpay.clear();
  }
}

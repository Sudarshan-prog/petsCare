import 'package:razorpay_flutter/razorpay_flutter.dart';

abstract class IPaymentRepository {
  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  });

  void openCheckout({
    required double amount,
    required String contact,
    required String email,
    required String description,
  });

  void dispose();
}

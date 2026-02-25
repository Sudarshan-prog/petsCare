import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../repositories/payment_repository_interface.dart';
import '../repositories/razorpay_repository.dart';

final paymentRepositoryProvider = Provider<IPaymentRepository>((ref) {
  return RazorpayRepository();
});

class PaymentState {
  final bool isLoading;
  final String? error;
  final String? paymentId;
  final bool isSuccess;

  PaymentState({
    this.isLoading = false,
    this.error,
    this.paymentId,
    this.isSuccess = false,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    String? paymentId,
    bool? isSuccess,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      paymentId: paymentId ?? this.paymentId,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final IPaymentRepository _repository;

  PaymentNotifier(this._repository) : super(PaymentState());

  void init() {
    _repository.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void startPayment({
    required double amount,
    required String contact,
    required String email,
    required String description,
  }) {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    _repository.openCheckout(
      amount: amount,
      contact: contact,
      email: email,
      description: description,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    state = state.copyWith(
      isLoading: false,
      isSuccess: true,
      paymentId: response.paymentId,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    state = state.copyWith(
      isLoading: false,
      isSuccess: false,
      error: response.message ?? 'Payment Failed',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    state = state.copyWith(isLoading: false);
    // Handle external wallet if needed
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return PaymentNotifier(repo);
});

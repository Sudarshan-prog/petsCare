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

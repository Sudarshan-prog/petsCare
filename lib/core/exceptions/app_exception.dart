/// Unified exception class for all CareBridge repository errors.
/// Provides consistent error messages to the UI layer while
/// preserving the original error for debugging.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => code != null ? '[$code] $message' : message;

  /// User-friendly message for SnackBars and dialogs
  String get userMessage {
    switch (code) {
      case 'permission-denied':
        return 'You don\'t have permission for this action.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      case 'network-error':
        return 'No internet connection. Please check your network.';
      default:
        return message;
    }
  }
}

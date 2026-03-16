/// PHASE 0: Type-safe status enums — eliminates string typos and
/// provides compile-time safety for booking state transitions.

enum BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  /// Valid transitions per role (enforced server-side in Phase 1)
  /// Owner can:   pending→cancelled, confirmed→completed, confirmed→cancelled
  /// Caretaker can: pending→confirmed, pending→cancelled, confirmed→cancelled
  bool canTransitionTo(BookingStatus next) {
    switch (this) {
      case BookingStatus.pending:
        return next == BookingStatus.confirmed ||
            next == BookingStatus.cancelled;
      case BookingStatus.confirmed:
        return next == BookingStatus.completed ||
            next == BookingStatus.cancelled;
      case BookingStatus.completed:
        return false; // Terminal state
      case BookingStatus.cancelled:
        return false; // Terminal state
    }
  }

  static BookingStatus fromString(String s) => BookingStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => BookingStatus.pending,
      );

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum PaymentStatus {
  unpaid,
  authorized,
  paid,
  released,
  refunded,
  failed;

  static PaymentStatus fromString(String s) =>
      PaymentStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => PaymentStatus.unpaid,
      );

  String get displayName {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.authorized:
        return 'Authorized';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.released:
        return 'Released';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }
}

enum UserRole {
  owner,
  caretaker;

  static UserRole? fromString(String? s) {
    if (s == null) return null;
    return UserRole.values.firstWhere(
      (e) => e.name == s,
      orElse: () => UserRole.owner,
    );
  }
}

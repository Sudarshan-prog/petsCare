import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? profileUrl;
  final String? role; // 'owner' or 'caretaker'
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.profileUrl,
    this.role,
    this.phoneNumber,
    this.latitude,
    this.longitude,
  });

  /// Returns either the stored profile URL or a dynamically generated DiceBear avatar.
  /// This ensures zero Firebase Storage usage for profile pictures.
  String get effectiveProfileUrl {
    if (profileUrl != null && profileUrl!.isNotEmpty) return profileUrl!;
    return 'https://api.dicebear.com/7.x/adventurer/png?seed=$id&backgroundColor=b6e3f4,c0aede,d1d4f9';
  }

  factory AppUser.fromFirebase(
    User user, {
    String? role,
    String? phoneNumber,
    double? latitude,
    double? longitude,
  }) {
    return AppUser(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      profileUrl: user.photoURL,
      role: role,
      phoneNumber: phoneNumber,
      latitude: latitude,
      longitude: longitude,
    );
  }

  factory AppUser.fromFirestore(String uid, Map<String, dynamic> data) {
    return AppUser(
      id: uid,
      name: data['name'] ?? 'User',
      email: data['email'] ?? '',
      profileUrl: data['profileUrl'],
      role: data['role'],
      phoneNumber: data['phoneNumber'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileUrl': profileUrl,
      'role': role,
      'phoneNumber': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

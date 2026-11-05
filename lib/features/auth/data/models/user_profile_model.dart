import '../../domain/entities/user_profile.dart';

/// JSON form of a `user` row. The same keys are used for the Supabase response and for
/// the copy kept in secure storage.
extension UserProfileJson on UserProfile {
  Map<String, dynamic> toJson() => {
    'id': id,
    'auth_user_id': authUserId,
    'name': name,
    'email': email,
    'photo': photo,
    'primary_provider': primaryProvider,
    'platform': platform,
    'app_version': appVersion,
    'status': status,
    'fcm_token': fcmToken,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

UserProfile userProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: (json['id'] as num).toInt(),
  authUserId: json['auth_user_id'] as String,
  name: json['name'] as String?,
  email: json['email'] as String?,
  photo: json['photo'] as String?,
  primaryProvider: json['primary_provider'] as String?,
  platform: json['platform'] as String?,
  appVersion: json['app_version'] as String?,
  status: json['status'] as String?,
  fcmToken: json['fcm_token'] as String?,
  createdAt: _date(json['created_at']),
  updatedAt: _date(json['updated_at']),
);

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

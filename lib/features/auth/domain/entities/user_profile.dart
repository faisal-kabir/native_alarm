import 'package:equatable/equatable.dart';

/// The app's own record of the user: one row of the Supabase `user` table, kept on
/// the device so it is available at any time, even offline.
class UserProfile extends Equatable {
  /// `user.id` (the number other tables point to).
  final int id;

  /// `user.auth_user_id`: the Supabase Auth UUID this row belongs to.
  final String authUserId;

  final String? name;
  final String? email;
  final String? photo;

  /// How the user signs in: `anonymous`, `google`, `apple`, ...
  final String? primaryProvider;
  final String? platform;
  final String? appVersion;
  final String? status;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.authUserId,
    this.name,
    this.email,
    this.photo,
    this.primaryProvider,
    this.platform,
    this.appVersion,
    this.status,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    authUserId,
    name,
    email,
    photo,
    primaryProvider,
    platform,
    appVersion,
    status,
    fcmToken,
    createdAt,
    updatedAt,
  ];
}

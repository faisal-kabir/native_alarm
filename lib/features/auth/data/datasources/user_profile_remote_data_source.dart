import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/user_profile.dart';
import '../models/user_profile_model.dart';

abstract class UserProfileRemoteDataSource {
  /// The signed-in user's Supabase Auth UUID, or null when nobody is signed in.
  String? get authUserId;

  /// The signed-in user's row of the `user` table.
  Future<UserProfile> fetchProfile(String authUserId);

  /// Updates only `platform`, `app_version` (and `fcm_token` when [info] has one) of
  /// the user's row and returns the row as it is now.
  Future<UserProfile> updateDeviceInfo(String authUserId, DeviceInfo info);
}

@LazySingleton(as: UserProfileRemoteDataSource)
class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  final SupabaseClient client;

  UserProfileRemoteDataSourceImpl(this.client);

  @override
  String? get authUserId => client.auth.currentUser?.id;

  @override
  Future<UserProfile> fetchProfile(String authUserId) async {
    try {
      // Row-level security already limits this to the caller's own row; the filter
      // makes the intent explicit.
      final row = await client
          .from('user')
          .select()
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      if (row == null) throw const ServerException('No profile row yet');
      return userProfileFromJson(row);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserProfile> updateDeviceInfo(
    String authUserId,
    DeviceInfo info,
  ) async {
    try {
      final row = await client
          .from('user')
          .update({
            'platform': info.platform,
            'app_version': info.appVersion,
            'fcm_token': ?info.fcmToken,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('auth_user_id', authUserId)
          .select()
          .maybeSingle();
      if (row == null) throw const ServerException('No profile row to update');
      return userProfileFromJson(row);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

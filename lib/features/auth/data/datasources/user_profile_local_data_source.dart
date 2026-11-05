import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_profile.dart';
import '../models/user_profile_model.dart';

abstract class UserProfileLocalDataSource {
  Future<UserProfile?> read();
  Future<void> write(UserProfile profile);
  Future<void> clear();
}

/// Keeps the profile in the platform's secure storage (iOS Keychain, Android
/// Keystore-backed storage) as one JSON string.
@LazySingleton(as: UserProfileLocalDataSource)
class UserProfileLocalDataSourceImpl implements UserProfileLocalDataSource {
  static const String _key = 'user_profile';

  final FlutterSecureStorage storage;

  UserProfileLocalDataSourceImpl(this.storage);

  @override
  Future<UserProfile?> read() async {
    try {
      final raw = await storage.read(key: _key);
      if (raw == null) return null;
      return userProfileFromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> write(UserProfile profile) async {
    try {
      await storage.write(key: _key, value: jsonEncode(profile.toJson()));
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clear() async {
    try {
      await storage.delete(key: _key);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}

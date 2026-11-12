import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';

/// The ticket of a merge that has begun and not finished yet (see
/// `AuthRemoteDataSource.startMerge`). It is the only proof that the anonymous user's
/// goals and alarms belong to this device, so it is kept until the server confirms the
/// merge, across restarts.
abstract class PendingMergeLocalDataSource {
  Future<String?> read();
  Future<void> write(String ticket);
  Future<void> clear();
}

@LazySingleton(as: PendingMergeLocalDataSource)
class PendingMergeLocalDataSourceImpl implements PendingMergeLocalDataSource {
  static const String _key = 'pending_account_merge';

  final FlutterSecureStorage storage;

  PendingMergeLocalDataSourceImpl(this.storage);

  @override
  Future<String?> read() => _guard(() => storage.read(key: _key));

  @override
  Future<void> write(String ticket) =>
      _guard(() => storage.write(key: _key, value: ticket));

  @override
  Future<void> clear() => _guard(() => storage.delete(key: _key));

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}

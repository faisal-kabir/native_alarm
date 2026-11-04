import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_info.dart';

abstract class AppInfoDataSource {
  Future<AppInfo> getAppInfo();
}

@LazySingleton(as: AppInfoDataSource)
class AppInfoDataSourceImpl implements AppInfoDataSource {
  @override
  Future<AppInfo> getAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppInfo(
        name: info.appName,
        version: info.version,
        build: info.buildNumber,
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}

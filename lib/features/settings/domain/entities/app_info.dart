import 'package:equatable/equatable.dart';

/// Name, version and build number of the installed app.
class AppInfo extends Equatable {
  final String name;
  final String version;
  final String build;

  const AppInfo({
    required this.name,
    required this.version,
    required this.build,
  });

  @override
  List<Object?> get props => [name, version, build];
}

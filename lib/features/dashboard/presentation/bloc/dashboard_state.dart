import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  /// 0 = My Alarms, 1 = Reasons, 2 = Settings.
  final int selectedIndex;

  const DashboardState({this.selectedIndex = 0});

  @override
  List<Object?> get props => [selectedIndex];
}

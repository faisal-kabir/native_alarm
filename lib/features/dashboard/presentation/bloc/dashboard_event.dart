import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// The visible tab changed (a tab was tapped or the pages were swiped).
class DashboardTabChangedEvent extends DashboardEvent {
  final int index;

  const DashboardTabChangedEvent(this.index);

  @override
  List<Object?> get props => [index];
}

/// The app opened or came back to the foreground: make sure a Supabase session
/// exists (an anonymous one for now). Cheap when a session is already saved.
class EnsureSessionEvent extends DashboardEvent {
  const EnsureSessionEvent();
}

/// Firebase issued or refreshed the FCM token: pass it on to the server.
class FcmTokenChangedEvent extends DashboardEvent {
  const FcmTokenChangedEvent();
}

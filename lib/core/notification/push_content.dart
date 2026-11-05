import 'package:firebase_messaging/firebase_messaging.dart';

/// What a push message should look like on screen.
class PushContent {
  final String title;
  final String body;

  /// The message's custom data, as text, handed back when the notification is tapped.
  final String? payload;

  const PushContent({required this.title, required this.body, this.payload});

  /// Reads the title and body from the message's `notification` part, or from the
  /// `title` / `body` keys of its data for data-only messages. Null when the message
  /// has neither, so there is nothing to show.
  static PushContent? fromMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return null;
    return PushContent(
      title: title ?? '',
      body: body ?? '',
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }
}

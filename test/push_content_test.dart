import 'package:eala/core/notification/fcm_token.dart';
import 'package:eala/core/notification/push_content.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the notification part when the message has one', () {
    final content = PushContent.fromMessage(
      const RemoteMessage(
        notification: RemoteNotification(title: 'Hello', body: 'World'),
        data: {'screen': 'reasons'},
      ),
    );
    expect(content?.title, 'Hello');
    expect(content?.body, 'World');
    expect(content?.payload, '{screen: reasons}');
  });

  test('falls back to the data keys for data-only messages', () {
    final content = PushContent.fromMessage(
      const RemoteMessage(data: {'title': 'Data title', 'body': 'Data body'}),
    );
    expect(content?.title, 'Data title');
    expect(content?.body, 'Data body');
  });

  test('a message with nothing to show gives no content', () {
    expect(
      PushContent.fromMessage(const RemoteMessage(data: {'other': 'x'})),
      isNull,
    );
    expect(PushContent.fromMessage(const RemoteMessage()), isNull);
  });

  test('the fcmToken variable is readable and writable from anywhere', () {
    expect(fcmToken, isNull);
    fcmToken = 'abc';
    expect(fcmToken, 'abc');
    fcmToken = null;
  });

  test('every new token is announced on fcmTokenChanges', () async {
    final seen = <String>[];
    final sub = fcmTokenChanges.listen(seen.add);
    setFcmToken('first');
    setFcmToken(null); // no token: stored as null, nothing announced
    setFcmToken('second');
    await Future<void>.delayed(Duration.zero);
    expect(seen, ['first', 'second']);
    expect(fcmToken, 'second');
    await sub.cancel();
    setFcmToken(null);
  });
}

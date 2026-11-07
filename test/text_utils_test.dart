import 'package:eala/core/theme/app_color.dart';
import 'package:eala/core/utils/text_utils.dart';
import 'package:eala/core/widgets/rise_in.dart';
import 'package:eala/core/widgets/spring_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clipToWord keeps whole words within the limit', () {
    expect(clipToWord('short', 10), 'short');
    expect(clipToWord('one two three', 7), 'one two');
    expect(clipToWord('one two three', 8), 'one two');
    // No space late enough: cut hard rather than lose most of the text.
    expect(clipToWord('abcdefghij klm', 8), 'abcdefgh');
  });

  test('wordCount counts runs of non-space characters', () {
    expect(wordCount(''), 0);
    expect(wordCount('   '), 0);
    expect(wordCount(' one  two\nthree '), 3);
  });

  test('initialOf gives the capital first letter, empty for nothing', () {
    expect(initialOf(' health'), 'H');
    expect(initialOf('élan'), 'É');
    expect(initialOf('👍 yes'), '👍');
    expect(initialOf('   '), '');
  });

  test('AppColor.tintOf falls back to the brand colour', () {
    expect(AppColor.tintOf(null), AppColor.primary);
    expect(AppColor.tintOf(0xFF30D158), const Color(0xFF30D158));
  });

  testWidgets(
    'SpringIn and RiseIn show their child at once with reduced motion',
    (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                SpringIn(
                  spring: SpringDescription(
                    mass: 1,
                    stiffness: 260,
                    damping: 20,
                  ),
                  delay: Duration(seconds: 1),
                  child: Text('seal'),
                ),
                RiseIn(
                  delay: Duration(seconds: 1),
                  blur: 2,
                  child: Text('row'),
                ),
              ],
            ),
          ),
        ),
      );
      final fade = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.text('seal'),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, 1);
      // RiseIn makes no animation at all.
      expect(
        find.ancestor(
          of: find.text('row'),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
    },
  );
}

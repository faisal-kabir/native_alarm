import 'package:eala/core/utils/text_utils.dart';
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
}

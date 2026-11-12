import 'package:eala/core/utils/name_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeName', () {
    test('keeps letters of any script, spaces, hyphens and apostrophes', () {
      for (final name in [
        "Anne-Marie",
        "O'Brien",
        'Mary Jane',
        'José',
        'Zoë',
        'علي',
        '田中',
      ]) {
        expect(sanitizeName(name), name);
      }
    });

    test('drops digits, emoji and punctuation as they are typed', () {
      expect(sanitizeName('Al3x!'), 'Alx');
      expect(sanitizeName('Sam 🙂'), 'Sam ');
      expect(sanitizeName('seven7'), 'seven');
      expect(sanitizeName('a_b.c@d'), 'abcd');
    });

    test('runs of spaces become one, and it stops at 24', () {
      expect(sanitizeName('Mary    Jane'), 'Mary Jane');
      expect(sanitizeName('A' * 40).length, maxNameLength);
    });
  });

  group('isValidName', () {
    test('two letters is the least, 24 the most', () {
      expect(isValidName('Al'), isTrue);
      expect(isValidName('A'), isFalse);
      expect(isValidName('A' * 24), isTrue);
      expect(isValidName('A' * 25), isFalse);
    });

    test('spaces around it do not count', () {
      expect(isValidName('  Sam  '), isTrue);
      expect(isValidName('   '), isFalse);
      expect(isValidName(''), isFalse);
    });

    test('it starts with a letter and holds nothing a voice can not say', () {
      expect(isValidName('-Sam'), isFalse);
      expect(isValidName("'Sam"), isFalse);
      expect(isValidName('7am'), isFalse);
      expect(isValidName('Sam7'), isFalse);
      expect(isValidName('Sam!'), isFalse);
      expect(isValidName("Anne-Marie O'Brien"), isTrue);
    });
  });
}

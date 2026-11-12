/// The one name this product says out loud.
///
/// `user.name` is interpolated into every wake-up message and spoken by a synthetic
/// voice each morning, so what can land in the field is narrower than an ordinary text
/// input. Everything that collects or saves a name goes through these two functions.
library;

/// Short enough that nobody with a genuinely short name is turned away; long enough
/// that a stray keystroke can not pass as one.
const int minNameLength = 2;

/// The cap on a name.
const int maxNameLength = 24;

final RegExp _notNameChars = RegExp(r"[^\p{L}\p{M}'\- ]", unicode: true);
final RegExp _manySpaces = RegExp(r'\s{2,}');

/// What survives a keystroke: letters of any script (and the marks some scripts spell as
/// their own character), a space ("Mary Jane"), a hyphen ("Anne-Marie"), an apostrophe
/// ("O'Brien"); runs of spaces become one; at most [maxNameLength] characters.
String sanitizeName(String raw) {
  final clean = raw.replaceAll(_notNameChars, '').replaceAll(_manySpaces, ' ');
  return clean.length > maxNameLength
      ? clean.substring(0, maxNameLength)
      : clean;
}

final RegExp _nameShape = RegExp(r"^\p{L}[\p{L}\p{M}'\- ]*$", unicode: true);

/// Whether [name] can be saved: starts with a letter, holds nothing but what
/// [sanitizeName] keeps, and is [minNameLength] to [maxNameLength] characters.
bool isValidName(String name) {
  final clean = name.trim();
  return clean.length >= minNameLength &&
      clean.length <= maxNameLength &&
      _nameShape.hasMatch(clean);
}

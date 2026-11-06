// Helpers for reading values the server sends (shared by every remote model).

/// A server text value, trimmed; null when it is missing, not text, or blank.
String? cleanText(Object? value) {
  final text = value is String ? value.trim() : '';
  return text.isEmpty ? null : text;
}

/// `"#C96B4B"` / `"C96B4B"` / `"#FFC96B4B"` to an ARGB int; null on anything else.
int? parseHexColor(String? hex) {
  final digits = (hex ?? '').trim().replaceFirst('#', '');
  final value = int.tryParse(digits, radix: 16);
  if (value == null) return null;
  return switch (digits.length) {
    6 => 0xFF000000 | value,
    8 => value,
    _ => null,
  };
}

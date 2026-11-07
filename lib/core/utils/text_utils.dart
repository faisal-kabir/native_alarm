import 'package:flutter/widgets.dart';

/// Cuts [text] to at most [max] characters at the last whole word that fits, so text
/// that runs over a limit loses a trailing word rather than half of one.
String clipToWord(String text, int max) {
  if (text.length <= max) return text;
  if (RegExp(r'\s').hasMatch(text[max])) {
    return text.substring(0, max).trimRight();
  }
  final cut = text.substring(0, max);
  final space = cut.lastIndexOf(' ');
  return (space > max * 0.6 ? cut.substring(0, space) : cut).trimRight();
}

/// How many words [text] has (runs of non-space characters).
int wordCount(String text) {
  final t = text.trim();
  return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
}

/// The first letter of [name] in capitals ("health" → "H"), for the letter shown when
/// there is no picture or icon; empty for an empty name.
String initialOf(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '' : trimmed.characters.first.toUpperCase();
}

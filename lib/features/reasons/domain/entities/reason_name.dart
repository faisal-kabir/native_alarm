/// The name for a new reason so that the user never has two of the same name:
/// [base] itself when none of [taken] is [base] or "[base] N"; otherwise [base]
/// followed by one more than the highest number in use ([base] alone counts as 1),
/// e.g. "Stronger Every Day 3" after "Stronger Every Day" and "... 2".
String nextReasonName(String base, Iterable<String> taken) {
  final name = base.trim();
  final numbered = RegExp('^${RegExp.escape(name)} (\\d+)\$');
  var highest = 0;
  for (final t in taken) {
    final other = t.trim();
    if (other == name) {
      if (highest < 1) highest = 1;
      continue;
    }
    final n = int.tryParse(numbered.firstMatch(other)?.group(1) ?? '');
    if (n != null && n > highest) highest = n;
  }
  return highest == 0 ? name : '$name ${highest + 1}';
}

import '../../../core/constants/app_constant.dart';
import 'entities/goal_topic.dart';

/// The ends of the chip steps ([AppConstant.topicChipSteps]), as counts of chips; the
/// last is [total].
List<int> chipSteps(int total) => [
  for (final n in AppConstant.topicChipSteps)
    if (n < total) n,
  total,
];

String _norm(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

const Set<String> _filler = {
  'my',
  'a',
  'an',
  'the',
  'to',
  'of',
  'for',
  'and',
  'i',
  'be',
  'being',
  'get',
  'getting',
};

/// Typing is a search. A chip matches when its name starts with what was typed, or
/// every word typed (filler words like "my" and "a" aside) starts a word of its name or
/// of its `keywords` ("stu" finds "My studies", "out debt" finds "Getting out of debt",
/// "gym" finds "Getting fit").
bool topicMatches(GoalTopic topic, String text) {
  final q = _norm(text);
  if (q.isEmpty) return false;
  final name = _norm(topic.label);
  if (name.startsWith(q)) return true;
  final words = q.split(' ').where((w) => !_filler.contains(w)).toList();
  if (words.isEmpty) return false;
  final own = [
    ...name.split(' '),
    ...topic.keywords.split(' ').where((w) => w.isNotEmpty),
  ];
  return words.every((w) => own.any((o) => o.startsWith(w)));
}

/// Typing a chip's name exactly (case and punctuation aside) is the same answer as
/// tapping it: that chip, or null when the text names none.
GoalTopic? topicNamed(List<GoalTopic> topics, String text) {
  final q = _norm(text);
  if (q.isEmpty) return null;
  for (final topic in topics) {
    if (_norm(topic.label) == q) return topic;
  }
  return null;
}

final RegExp _gentleWords = RegExp(
  r'\b(sober|sobriety|drink|alcohol|addict|relapse|recover|grie|griev|loss|lost my|passed away|died|anxi|depress|heal|therap|trauma|panic|cancer|illness|chronic|diagnos|chemo|smok|vap|caregiv|hospice|divorce|miscarr)',
  caseSensitive: false,
);

/// A topic the person typed that needs gentleness, by its words. It stands in for the
/// server's sensitivity check, which reads meaning rather than words.
bool isGentleText(String text) => _gentleWords.hasMatch(text);

/// What the first step's answer is: the picked chip, or the person's own words.
class TopicAnswer {
  const TopicAnswer({this.chip, this.text = ''});

  /// The chip when one was tapped or its exact name typed; null for the person's own.
  final GoalTopic? chip;

  /// The typed text (empty when a chip was tapped).
  final String text;

  /// The label that names the goal: the chip's, else the typed words.
  String get label => chip?.label ?? text.trim();

  /// Whether the goal must be spoken to gently: the chip's own mark, or the words.
  bool get gentle => chip != null ? chip!.gentle : isGentleText(text);

  /// Enough to continue.
  bool get ready =>
      chip != null || text.trim().length >= AppConstant.topicMinLength;
}

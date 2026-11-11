import 'package:equatable/equatable.dart';

/// One thing a person can wake up for ("Getting fit", "My family", ...): a chip of the
/// first step of Create Goal, with the goals and the whys the next two steps suggest for
/// it. The whole list lives on the server (tables `goal_topic`, `goal_suggestion` and
/// `why_suggestion`), so wording can change without an app update.
class GoalTopic extends Equatable {
  final int id;

  /// The chip's text, at most 20 characters; it becomes the goal's name.
  final String label;

  /// Tender ground (grief, sobriety, illness...): the writer is asked never to shame,
  /// guilt or blame. Every tone is still offered.
  final bool gentle;

  /// Extra words the search matches ("gym" finds "Getting fit"), space separated.
  final String keywords;

  /// The position of the chip (1 = first); the chips arrive in steps by it.
  final int sortOrder;

  /// The goals the Goal step suggests for this chip, in order.
  final List<String> goals;

  /// The whys the Why step suggests for this chip, in order.
  final List<String> whys;

  const GoalTopic({
    required this.id,
    required this.label,
    this.gentle = false,
    this.keywords = '',
    this.sortOrder = 0,
    this.goals = const [],
    this.whys = const [],
  });

  @override
  List<Object?> get props => [
    id,
    label,
    gentle,
    keywords,
    sortOrder,
    goals,
    whys,
  ];
}

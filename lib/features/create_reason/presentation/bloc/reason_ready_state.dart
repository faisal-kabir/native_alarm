import 'package:equatable/equatable.dart';

class ReasonReadyState extends Equatable {
  final int id;

  /// The reason's name as shown (changes at once on a rename).
  final String name;

  /// Goes up by one every time a rename fails (the name is put back), so the page
  /// can say so.
  final int renameFailures;

  const ReasonReadyState({
    this.id = 0,
    this.name = '',
    this.renameFailures = 0,
  });

  ReasonReadyState copyWith({int? id, String? name, int? renameFailures}) =>
      ReasonReadyState(
        id: id ?? this.id,
        name: name ?? this.name,
        renameFailures: renameFailures ?? this.renameFailures,
      );

  @override
  List<Object?> get props => [id, name, renameFailures];
}

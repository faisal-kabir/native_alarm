import 'package:equatable/equatable.dart';

import '../../../../core/network/media_url.dart';
import 'voice_group.dart';

/// A voice the user can pick for a reason (table `voice` on the server).
///
/// [audio] (a sample) and [avatar] (the picture) are file **paths** on the server;
/// read them through [audioUrl] / [avatarUrl], which add the base URL, never use the
/// raw path to play or load a file.
class Voice extends Equatable {
  final int id;
  final String name;

  /// The provider's own id of this voice.
  final String voiceId;
  final String? audio;
  final String? avatar;
  final int? groupId;

  /// The heading this voice is listed under (from `voice_group`, joined on
  /// `group_id`); null when it has none.
  final VoiceGroup? group;
  final String? gender;
  final String? accent;

  /// Descriptive words as the server sends them (one text).
  final String? traits;

  /// Tint as an ARGB value (`0xFFRRGGBB`); null when the server sent none.
  final int? color;
  final bool isPremium;

  const Voice({
    required this.id,
    required this.name,
    required this.voiceId,
    this.audio,
    this.avatar,
    this.groupId,
    this.group,
    this.gender,
    this.accent,
    this.traits,
    this.color,
    this.isPremium = false,
  });

  /// Full URL of the sample audio, or null when the voice has none.
  String? get audioUrl => audio == null ? null : mediaUrl(audio!);

  /// Full URL of the avatar picture, or null when the voice has none.
  String? get avatarUrl => avatar == null ? null : mediaUrl(avatar!);

  @override
  List<Object?> get props => [
    id,
    name,
    voiceId,
    audio,
    avatar,
    groupId,
    group,
    gender,
    accent,
    traits,
    color,
    isPremium,
  ];
}

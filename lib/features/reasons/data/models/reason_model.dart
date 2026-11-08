import '../../../../core/constants/app_constant.dart';
import '../../../../core/utils/server_value.dart';
import '../../../area_of_life/data/models/area_of_life_model.dart';
import '../../../sound/data/models/sound_type_model.dart';
import '../../../voice/data/models/voice_model.dart';
import '../../domain/entities/reason.dart';

/// What to ask the server for one reason: the row, and over its foreign keys the area
/// (`area_id`), the sound (`sound_type_id`) and the voice (`voice_id`, with the voice's
/// group) - one request, one object.
const String reasonSelect =
    '*, area_of_life(*), sound_type(*), voice(*, voice_group(id, title, description))';

/// A `reason` row as the server sends it ([reasonSelect], snake_case keys).
Reason reasonFromJson(Map<String, dynamic> json) {
  Map<String, dynamic>? joined(String key) => json[key] is Map<String, dynamic>
      ? json[key] as Map<String, dynamic>
      : null;
  final area = joined('area_of_life');
  final sound = joined('sound_type');
  final voice = joined('voice');
  int id(String key) => (json[key] as num?)?.toInt() ?? 0;
  return Reason(
    id: id('id'),
    name: cleanText(json['name']) ?? '',
    purpose: cleanText(json['purpose']) ?? '',
    why: cleanText(json['why']) ?? '',
    lengthSeconds:
        (json['length'] as num?)?.toInt() ??
        AppConstant.defaultReasonLengthSeconds,
    areaId: id('area_id'),
    area: area == null ? null : AreaOfLifeModel.fromJson(area),
    soundTypeId: id('sound_type_id'),
    sound: sound == null ? null : SoundTypeModel.fromJson(sound),
    voiceId: id('voice_id'),
    voice: voice == null ? null : VoiceModel.fromJson(voice),
    createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal(),
  );
}

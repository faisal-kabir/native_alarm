import '../../../../core/constants/app_constant.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/animated_select_list.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../area_of_life/domain/entities/area_of_life.dart';
import '../../../sound/domain/entities/sound_type.dart';

/// The choice rows of a reason, the same wherever they are chosen (the Create Reason
/// steps and the reason's own screen).

/// An area of life as a choice row: its title, description, tint and icon.
SelectItem areaChoice(AreaOfLife area) => SelectItem(
  id: area.id,
  title: area.title,
  subtitle: area.description,
  tint: AppColor.tintOf(area.color),
  iconPath: area.icon,
);

/// A sound (tone) as a choice row.
SelectItem soundChoice(SoundType sound) => SelectItem(
  id: sound.id,
  title: sound.title,
  subtitle: sound.description,
  tint: AppColor.tintOf(sound.color),
  iconPath: sound.icon,
);

/// A length ([AppConstant.reasonLengthsSeconds]) as a choice row: "Short", its note,
/// "30s" in the tile.
SelectItem lengthChoice(AppLocalizations strings, int seconds) => SelectItem(
  id: seconds,
  title: reasonLengthName(strings, seconds),
  subtitle: reasonLengthNote(strings, seconds),
  tint: AppColor.primary,
  tileText: '${seconds}s',
);

/// "Short" for 30 seconds, "Standard" for 45; "N sec" for any other.
String reasonLengthName(AppLocalizations strings, int seconds) =>
    switch (seconds) {
      30 => strings.create_reason_length_30,
      45 => strings.create_reason_length_45,
      _ => strings.seconds_short(seconds),
    };

/// The one line about a length ("Quick and to the point.").
String reasonLengthNote(AppLocalizations strings, int seconds) =>
    switch (seconds) {
      30 => strings.create_reason_length_30_note,
      45 => strings.create_reason_length_45_note,
      _ => '',
    };

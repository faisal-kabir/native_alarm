import 'package:flutter/material.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/reason_area.dart';
import '../../domain/entities/reason_tone.dart';

/// Whether an alarm plays a reason: none = no badge, on = orange, off = grey.
enum ReasonAlarmBadge { none, on, off }

/// How an area of life looks: its tint colour, SVG icon and localized name.
extension ReasonAreaView on ReasonArea {
  Color get tint => switch (this) {
    ReasonArea.health => AppColor.areaHealth,
    ReasonArea.healing => AppColor.areaHealing,
    ReasonArea.fitness => AppColor.areaFitness,
    ReasonArea.career => AppColor.areaCareer,
    ReasonArea.family => AppColor.areaFamily,
    ReasonArea.money => AppColor.areaMoney,
    ReasonArea.growth => AppColor.areaGrowth,
    ReasonArea.business => AppColor.areaBusiness,
    ReasonArea.study => AppColor.areaStudy,
    ReasonArea.relationships => AppColor.areaRelationships,
  };

  SvgGenImage get icon => switch (this) {
    ReasonArea.health => Assets.icons.area.health,
    ReasonArea.healing => Assets.icons.area.healing,
    ReasonArea.fitness => Assets.icons.area.fitness,
    ReasonArea.career => Assets.icons.area.career,
    ReasonArea.family => Assets.icons.area.family,
    ReasonArea.money => Assets.icons.area.money,
    ReasonArea.growth => Assets.icons.area.growth,
    ReasonArea.business => Assets.icons.area.business,
    ReasonArea.study => Assets.icons.area.study,
    ReasonArea.relationships => Assets.icons.area.relationships,
  };

  String label(AppLocalizations strings) => switch (this) {
    ReasonArea.health => strings.reason_area_health,
    ReasonArea.healing => strings.reason_area_healing,
    ReasonArea.fitness => strings.reason_area_fitness,
    ReasonArea.career => strings.reason_area_career,
    ReasonArea.family => strings.reason_area_family,
    ReasonArea.money => strings.reason_area_money,
    ReasonArea.growth => strings.reason_area_growth,
    ReasonArea.business => strings.reason_area_business,
    ReasonArea.study => strings.reason_area_study,
    ReasonArea.relationships => strings.reason_area_relationships,
  };
}

extension ReasonToneView on ReasonTone {
  String label(AppLocalizations strings) => switch (this) {
    ReasonTone.encouraging => strings.reason_tone_encouraging,
    ReasonTone.calm => strings.reason_tone_calm,
    ReasonTone.focused => strings.reason_tone_focused,
    ReasonTone.challenge => strings.reason_tone_challenge,
    ReasonTone.playful => strings.reason_tone_playful,
  };
}

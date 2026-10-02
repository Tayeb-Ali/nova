import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nova/l10n/generated/app_localizations.dart";
import "package:tutorial_coach_mark/tutorial_coach_mark.dart";

import "tour_service.dart";

// Small replay button content agents place on their screens: starts the
// [tourId] tour built by [buildTargets].
class TourButton extends ConsumerWidget {
  const TourButton({
    super.key,
    required this.tourId,
    required this.buildTargets,
  });

  final String tourId;
  final List<TargetFocus> Function(AppLocalizations) buildTargets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.question_mark),
      tooltip: AppLocalizations.of(context).tourReplay,
      onPressed: () => TourService.startTour(context, ref, tourId, buildTargets),
    );
  }
}

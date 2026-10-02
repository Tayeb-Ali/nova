import "package:flutter_riverpod/legacy.dart";

// True while a coach-mark tour overlay is on screen. [TourService.startTour]
// sets it on start and clears it on finish/skip (try/finally). Shell chrome
// (floating bell, bottom bar) hides while this is true.
final tourActiveProvider = StateProvider<bool>((_) => false);

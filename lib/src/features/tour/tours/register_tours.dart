import "../tour_service.dart";
import "hub_tour.dart";

// Startup wiring for tour content builders.
//
// The integration agent calls [registerTours] ONCE at startup (it may not
// live in app.dart/main.dart — those files are owned by the integration
// agent). This file sets the hub builder only; the integration agent MERGES
// any secondary-agent builder lines here rather than editing competing
// files. The editor tour needs no static: its TourButton passes
// buildEditorTargets directly.
void registerTours() {
  TourService.hubTargetsBuilder = buildHubTargets;
}

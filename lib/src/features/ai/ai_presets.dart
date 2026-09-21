// Provider presets for the AI settings card.
//
// All four presets speak the OpenAI-compatible chat-completions API that
// [AiClient] implements, so no per-provider client code is needed:
// - OpenAI and xAI Grok are natively OpenAI-compatible.
// - OpenRouter is an OpenAI-compatible gateway.
// - Google AI Studio exposes an OpenAI-compatible endpoint under
//   `.../v1beta/openai/` (plain `v1beta` uses a different schema).
class AiPreset {
  final String id;
  final String label;
  final String baseUrl;
  final String model;

  const AiPreset({
    required this.id,
    required this.label,
    required this.baseUrl,
    required this.model,
  });
}

const List<AiPreset> aiPresets = [
  AiPreset(
    id: "openai",
    label: "OpenAI (GPT)",
    baseUrl: "https://api.openai.com/v1",
    model: "gpt-4o-mini",
  ),
  AiPreset(
    id: "openrouter",
    label: "OpenRouter",
    baseUrl: "https://openrouter.ai/api/v1",
    model: "openai/gpt-4o-mini",
  ),
  AiPreset(
    id: "google",
    label: "Google AI Studio (Gemini)",
    baseUrl: "https://generativelanguage.googleapis.com/v1beta/openai/",
    model: "gemini-2.0-flash",
  ),
  AiPreset(
    id: "grok",
    label: "xAI (Grok)",
    baseUrl: "https://api.x.ai/v1",
    model: "grok-3-mini",
  ),
];

AiPreset? aiPresetById(String id) {
  for (final preset in aiPresets) {
    if (preset.id == id) return preset;
  }
  return null;
}

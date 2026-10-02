// First-launch language picker: shown once, defaults to English.
//
// The app locale is forced to English until the user confirms (see NovaApp),
// so every string here reads from the English translations.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../l10n/generated/app_localizations.dart";
import "../../core/settings_store.dart";

/// One row of the picker: locale code, native label, English label.
class _Lang {
  const _Lang(this.code, this.native, this.english);
  final String code;
  final String native;
  final String english;
}

const _langs = [
  _Lang("ar", "العربية", "Arabic"),
  _Lang("en", "English", "English"),
  _Lang("fr", "Français", "French"),
  _Lang("es", "Español", "Spanish"),
  _Lang("ru", "Русский", "Russian"),
  _Lang("zh", "中文", "Chinese"),
];

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String _selected = SettingsStore.defaultLocale;
  bool _saving = false;

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(settingsStoreProvider.notifier).chooseLanguage(_selected);
    } catch (_) {
      // Choice persistence must never trap the user; the gate re-asks.
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ">_",
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.langTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.langSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _langs.length,
                  itemBuilder: (context, i) {
                    final lang = _langs[i];
                    final tile = _LangTile(
                      lang: lang,
                      selected: _selected == lang.code,
                      onTap: () => setState(() => _selected = lang.code),
                    );
                    if (reduceMotion) return tile;
                    // Staggered entrance: slide-up + fade, one delay per row.
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 350 + i * 70),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) => Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, 24 * (1 - t)),
                          child: child,
                        ),
                      ),
                      child: tile,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saving ? null : _confirm,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.langContinue),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final _Lang lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Material carries the background (ListTile paints its ink on the
    // nearest Material — a plain Container behind it triggers a framework
    // assertion and hides ripples).
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.45)
            : scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        title: Text(
          lang.native,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: lang.native == lang.english
            ? null
            : Text(lang.english),
        trailing: AnimatedScale(
          scale: selected ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Icon(Icons.check_circle, color: scheme.primary),
        ),
        onTap: onTap,
        ),
      ),
    );
  }
}

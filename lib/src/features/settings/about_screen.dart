import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:url_launcher/url_launcher.dart";

import "../../../l10n/generated/app_localizations.dart";
import "../../core/app_config.dart";
import "../../core/services/app_info_service.dart";

/// Settings > About & Contact: what Nova is, where to download it
/// (Play vs GitHub and how they differ), project links, and how to
/// reach us. All URLs/emails live in [AppConfig]; all labels are
/// localized — no hardcoded user-facing strings here.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).aboutOpenFailed)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).aboutOpenFailed)),
        );
      }
    }
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).aboutCopied)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    ShapeBorder sectionShape() => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: scheme.outlineVariant),
    );
    Widget sectionTitle(String text) => Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: scheme.primary,
        letterSpacing: 1.2,
      ),
    );
    Widget linkRow({
      required IconData icon,
      required String title,
      String? subtitle,
      required String value,
      Uri? uri,
    }) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: scheme.primary),
        title: Text(title, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null
            ? Text(
                value,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subtitle),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.actionCopy,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_outlined, size: 18),
              onPressed: () => _copy(context, value),
            ),
            if (uri != null)
              IconButton(
                tooltip: l10n.actionOpen,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.open_in_new_outlined, size: 18),
                onPressed: () => _open(context, uri),
              ),
          ],
        ),
        onTap: uri == null ? null : () => _open(context, uri),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          // App header: icon + name + version + tagline.
          Card(
            elevation: 0,
            color: scheme.surfaceContainer,
            shape: sectionShape(),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.terminal_outlined,
                    size: 48,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Nova",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (AppInfo.isLoaded)
                          Text(
                            l10n.appVersionBuild(
                              AppInfo.version,
                              AppInfo.buildNumber,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        Text(
                          l10n.aboutTagline,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // About Nova.
          Card(
            elevation: 0,
            color: scheme.surfaceContainer,
            shape: sectionShape(),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle(l10n.aboutSectionAbout),
                  const SizedBox(height: 8),
                  Text(l10n.aboutDescription),
                ],
              ),
            ),
          ),
          // Download: Play + GitHub + which-one explainer.
          Card(
            elevation: 0,
            color: scheme.surfaceContainer,
            shape: sectionShape(),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle(l10n.aboutSectionDownload),
                  const SizedBox(height: 4),
                  linkRow(
                    icon: Icons.play_arrow_outlined,
                    title: l10n.aboutPlayTitle,
                    subtitle: l10n.aboutPlaySub,
                    value: AppConfig.playStoreUrl,
                    uri: Uri.parse(AppConfig.playStoreUrl),
                  ),
                  const Divider(height: 8),
                  linkRow(
                    icon: Icons.code_outlined,
                    title: l10n.aboutGithubTitle,
                    subtitle: l10n.aboutGithubSub,
                    value: AppConfig.githubReleasesUrl,
                    uri: Uri.parse(AppConfig.githubReleasesUrl),
                  ),
                  const Divider(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.help_outline,
                      color: scheme.primary,
                    ),
                    title: Text(l10n.aboutVersionsTitle),
                    subtitle: Text(l10n.aboutVersionsBody),
                  ),
                ],
              ),
            ),
          ),
          // Project links.
          Card(
            elevation: 0,
            color: scheme.surfaceContainer,
            shape: sectionShape(),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle(l10n.aboutSectionProject),
                  const SizedBox(height: 4),
                  linkRow(
                    icon: Icons.source_outlined,
                    title: l10n.aboutSourceCode,
                    value: AppConfig.githubRepoUrl,
                    uri: Uri.parse(AppConfig.githubRepoUrl),
                  ),
                  const Divider(height: 8),
                  linkRow(
                    icon: Icons.new_releases_outlined,
                    title: l10n.aboutReleases,
                    value: AppConfig.githubReleasesUrl,
                    uri: Uri.parse(AppConfig.githubReleasesUrl),
                  ),
                  const Divider(height: 8),
                  linkRow(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.aboutPackageRepo,
                    value: "${AppConfig.repoUrl} ${AppConfig.repoSuite}",
                    uri: Uri.parse(AppConfig.repoUrl),
                  ),
                  const Divider(height: 8),
                  linkRow(
                    icon: Icons.balance_outlined,
                    title: l10n.aboutLicense,
                    subtitle: l10n.aboutLicenseSub,
                    value: Localizations.localeOf(context).languageCode == "ar"
                        ? AppConfig.licenseUrlAr
                        : AppConfig.licenseUrlEn,
                    uri: Uri.parse(
                      Localizations.localeOf(context).languageCode == "ar"
                          ? AppConfig.licenseUrlAr
                          : AppConfig.licenseUrlEn,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Contact us.
          Card(
            elevation: 0,
            color: scheme.surfaceContainer,
            shape: sectionShape(),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle(l10n.aboutSectionContact),
                  const SizedBox(height: 4),
                  linkRow(
                    icon: Icons.mail_outline,
                    title: l10n.aboutEmailUs,
                    subtitle: l10n.aboutEmailHint,
                    value: AppConfig.contactEmail,
                    uri: Uri(
                      scheme: "mailto",
                      path: AppConfig.contactEmail,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

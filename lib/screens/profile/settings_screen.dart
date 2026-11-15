import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/locale_provider.dart';
import '../../providers/spots_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trips_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/feedback.dart';
import '../../widgets/max_width.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _resetDemo(BuildContext context) async {
    final local = services.localBackend;
    if (local == null) return;
    final ok = await showConfirmSheet(
      context,
      title: 'Reset demo data?',
      message:
          'This restores the original seeded spots, trips and notifications.',
      confirmLabel: 'Reset',
      icon: Icons.restart_alt_rounded,
    );
    if (!ok || !context.mounted) return;
    final spotsP = context.read<SpotsProvider>();
    final tripsP = context.read<TripsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await local.reseed();
    await spotsP.load(force: true);
    await tripsP.load();
    messenger.showSnackBar(
      const SnackBar(content: Text('Demo data restored.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeP = context.watch<ThemeProvider>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: MaxWidthBox(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(context.tr('appearance'), style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(context.tr('system')),
                  icon: const Icon(Icons.brightness_auto_rounded),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(context.tr('light')),
                  icon: const Icon(Icons.light_mode_rounded),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(context.tr('dark')),
                  icon: const Icon(Icons.dark_mode_rounded),
                ),
              ],
              selected: {themeP.mode},
              onSelectionChanged: (s) => themeP.setMode(s.first),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _PreferredLanguageField(),
            const SizedBox(height: AppSpacing.xl),
            Text(context.tr('setup'), style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const _SettingsIcon(Icons.extension_outlined),
              title: Text(context.tr('integrations')),
              subtitle: Text(context.tr('integrationsSubtitle')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushNamed(context, AppRoutes.integrations),
            ),
            if (services.localBackend != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _SettingsIcon(Icons.restart_alt_rounded),
                title: Text(context.tr('resetDemo')),
                subtitle: Text(context.tr('resetDemoSubtitle')),
                onTap: () => _resetDemo(context),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const _SettingsIcon(Icons.info_outline_rounded),
              title: const Text('إسناد نقش جُبّة'),
              subtitle: const Text(
                'رسم رقمي عن صورة لريتشارد مورتل · CC BY 2.0',
              ),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => launchUrl(
                Uri.parse(
                  'https://commons.wikimedia.org/wiki/File:Thamudic_inscription_at_Jubbah_Rock_Art_Site,_Saudi_Arabia_(2).jpg',
                ),
                mode: LaunchMode.externalApplication,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Column(
                children: [
                  const AppLogo(size: 40),
                  const SizedBox(height: AppSpacing.md),
                  Text(AppConfig.tagline, style: text.bodySmall),
                  Text('Version ${AppConfig.version}', style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferredLanguageField extends StatelessWidget {
  const _PreferredLanguageField();

  @override
  Widget build(BuildContext context) {
    final localeP = context.watch<LocaleProvider>();
    return InputDecorator(
      decoration: InputDecoration(
        labelText: context.tr('language'),
        prefixIcon: const Icon(Icons.language_rounded),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: localeP.languageCode,
          hint: Text(context.tr('chooseLanguage')),
          items: [
            for (final entry in LocaleProvider.languages.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (code) async {
            if (code == null) return;
            try {
              await context.read<LocaleProvider>().setLanguage(code);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('languageSaved'))),
                );
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('languageError'))),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;
  const _SettingsIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
    );
  }
}

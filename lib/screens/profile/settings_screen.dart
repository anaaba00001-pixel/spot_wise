import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
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
    final userId = context.select<AuthProvider, String?>(
      (auth) => auth.user?.id,
    );
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: MaxWidthBox(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Appearance', style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_rounded),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_rounded),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_rounded),
                ),
              ],
              selected: {themeP.mode},
              onSelectionChanged: (s) => themeP.setMode(s.first),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (userId != null) ...[
              _PreferredLanguageField(key: ValueKey(userId), userId: userId),
              const SizedBox(height: AppSpacing.xl),
            ],
            Text('Setup', style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const _SettingsIcon(Icons.extension_outlined),
              title: const Text('Integrations & setup'),
              subtitle: const Text('Connect Firebase, Gemini and more — later'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushNamed(context, AppRoutes.integrations),
            ),
            if (services.localBackend != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _SettingsIcon(Icons.restart_alt_rounded),
                title: const Text('Reset demo data'),
                subtitle: const Text('Restore the original seeded content'),
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

class _PreferredLanguageField extends StatefulWidget {
  const _PreferredLanguageField({super.key, required this.userId});

  final String userId;

  @override
  State<_PreferredLanguageField> createState() =>
      _PreferredLanguageFieldState();
}

class _PreferredLanguageFieldState extends State<_PreferredLanguageField> {
  static const _languages = {
    'ar': 'العربية',
    'ur': 'الأردية',
    'en': 'الإنجليزية',
    'pa': 'البنجابية',
    'hi': 'الهندية',
    'id': 'الإندونيسية',
    'tr': 'التركية',
    'bn': 'البنغالية',
    'cy': 'الويلزية',
    'uz': 'الأوزبكية',
    'fr': 'الفرنسية',
    'ru': 'الروسية',
    'ha': 'الهوسا',
    'yo': 'اليوروبا',
    'ig': 'الإيغبو',
    'de': 'الألمانية',
    'zu': 'الزولو',
    'xh': 'الخوسا',
    'af': 'الأفريكانية',
    'sfs': 'لغة الإشارة الجنوب أفريقية',
    'am': 'الأمهرية',
    'om': 'الأورومية',
    'ti': 'التيغرينية',
    'so': 'الصومالية',
    'aa': 'العفرية',
    'sw': 'السواحيلية',
    'pt': 'البرتغالية',
    'es': 'الإسبانية',
  };

  final _preferences = SharedPreferencesAsync();
  late final Future<String?> _storedLanguage = _preferences.getString(
    _preferenceKey,
  );
  String? _selectedLanguage;
  bool _saving = false;

  String get _preferenceKey => 'preferred_language.${widget.userId}';

  Future<void> _saveLanguage(String? code) async {
    if (code == null || _saving) return;
    setState(() => _saving = true);
    try {
      await _preferences.setString(_preferenceKey, code);
      if (mounted) setState(() => _selectedLanguage = code);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر حفظ اللغة المفضلة. حاولي مرة أخرى.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _storedLanguage,
      builder: (context, snapshot) {
        final code = _selectedLanguage ?? snapshot.data;
        return InputDecorator(
          decoration: const InputDecoration(
            labelText: 'اللغة المفضلة',
            prefixIcon: Icon(Icons.language_rounded),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _languages.containsKey(code) ? code : null,
              hint: const Text('اختاري لغة'),
              items: [
                for (final entry in _languages.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged:
                  _saving || snapshot.connectionState != ConnectionState.done
                  ? null
                  : _saveLanguage,
            ),
          ),
        );
      },
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

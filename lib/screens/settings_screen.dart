import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/settings_controller.dart';
import '../theme/app_theme.dart';
import '../main.dart' show KiokuMark;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// The hosted privacy policy (also used as the App Store "Privacy Policy URL").
  static const String privacyUrl =
      'https://sites.google.com/view/rosomprivay/accueil';

  /// The hosted support page (also used as the App Store "Support URL").
  static const String supportUrl =
      'https://sites.google.com/view/rosomesuppor/accueil';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.t('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _sectionLabel(l.t('appearance')),
          _card(
            child: Column(
              children: [
                _rowLabel(Icons.brightness_6_rounded, l.t('theme')),
                const SizedBox(height: 12),
                _ThemeSelector(settings: settings, l: l),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionLabel(l.t('language')),
          _card(
            child: Column(
              children: [
                for (final loc in AppLocalizations.supportedLocales)
                  _LangTile(
                    code: loc.languageCode,
                    label: l.t('lang_${loc.languageCode}'),
                    selected: settings.locale?.languageCode == loc.languageCode,
                    onTap: () => settings.setLocale(loc),
                  ),
                _LangTile(
                  code: 'sys',
                  label: l.t('theme_system'),
                  selected: settings.locale == null,
                  onTap: () => settings.setLocale(null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionLabel(l.t('about')),
          _card(
            child: Row(
              children: [
                const KiokuMark(size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rosome', style: AppTheme.display(18)),
                      const SizedBox(height: 2),
                      Text('v1.0.0',
                          style: TextStyle(
                              color: AppColors.textLow, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => launchUrl(Uri.parse(privacyUrl),
                  mode: LaunchMode.externalApplication),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip_rounded,
                      size: 20, color: AppColors.primaryBright),
                  const SizedBox(width: 10),
                  Text(l.t('privacy_policy'),
                      style: TextStyle(
                          color: AppColors.textHigh,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(Icons.open_in_new_rounded,
                      size: 18, color: AppColors.textLow),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _card(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => launchUrl(Uri.parse(supportUrl),
                  mode: LaunchMode.externalApplication),
              child: Row(
                children: [
                  const Icon(Icons.help_outline_rounded,
                      size: 20, color: AppColors.primaryBright),
                  const SizedBox(width: 10),
                  Text(l.t('help_support'),
                      style: TextStyle(
                          color: AppColors.textHigh,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(Icons.open_in_new_rounded,
                      size: 18, color: AppColors.textLow),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.t('attribution'),
            style: TextStyle(
                color: AppColors.textLow, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                color: AppColors.textLow,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: child,
      );

  Widget _rowLabel(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryBright),
          const SizedBox(width: 10),
          Text(text,
              style: TextStyle(
                  color: AppColors.textHigh,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _ThemeSelector extends StatelessWidget {
  final SettingsController settings;
  final AppLocalizations l;
  const _ThemeSelector({required this.settings, required this.l});

  @override
  Widget build(BuildContext context) {
    final options = [
      (ThemeMode.system, Icons.brightness_auto_rounded, l.t('theme_system')),
      (ThemeMode.light, Icons.light_mode_rounded, l.t('theme_light')),
      (ThemeMode.dark, Icons.dark_mode_rounded, l.t('theme_dark')),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => settings.setThemeMode(o.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: settings.themeMode == o.$1
                        ? AppColors.brand
                        : null,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Column(
                    children: [
                      Icon(o.$2,
                          size: 20,
                          color: settings.themeMode == o.$1
                              ? Colors.white
                              : AppColors.textMid),
                      const SizedBox(height: 4),
                      Text(o.$3,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: settings.themeMode == o.$1
                                  ? Colors.white
                                  : AppColors.textMid)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangTile({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                    color: AppColors.textHigh,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primaryBright, size: 20)
            else
              Icon(Icons.circle_outlined,
                  color: AppColors.textLow.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

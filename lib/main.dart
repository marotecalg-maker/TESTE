import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kioku/screens/splash_screen.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/anime_provider.dart';
import 'screens/home_shell.dart';
import 'services/library_service.dart';
import 'services/settings_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/ui_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  await Hive.initFlutter();
  runApp(const KiokuApp());
}

class KiokuApp extends StatefulWidget {
  const KiokuApp({super.key});

  @override
  State<KiokuApp> createState() => _KiokuAppState();
}

class _KiokuAppState extends State<KiokuApp> {
  final LibraryService _library = LibraryService();
  final SettingsController _settings = SettingsController();
  final AnimeProvider _catalog = AnimeProvider();
  late final Future<void> _boot =
      Future.wait([_library.init(), _settings.init()]);

  @override
  void initState() {
    super.initState();
    // Load the bundled anime catalog (2,826 titles) off the main thread.
    // Fire-and-forget: it's only needed on the detail screen's Watch action,
    // so we don't hold the splash on the ~73 MB parse. AnimeProvider notifies
    // its listeners once the catalog is ready.
    _catalog.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LibraryService>.value(value: _library),
        ChangeNotifierProvider<SettingsController>.value(value: _settings),
        ChangeNotifierProvider<AnimeProvider>.value(value: _catalog),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Rosome',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              // Keep the custom palette in sync witha the resolved theme.
              AppColors.brightness = Theme.of(context).brightness;
              return child ?? const SizedBox.shrink();
            },
            home: FutureBuilder<void>(
              future: _boot,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SplashScreen();
                }
                return const LoadingScreen();
              },
            ),
          );
        },
      ),
    );
  }
}

/// Branded launch screen — the Kioku wordmark on the dark canvas.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: BackdropGlow()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const KiokuMark(size: 96),
                const SizedBox(height: 24),
                GradientText('Rosome',
                    style: AppTheme.display(44, weight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  'Your anime, remembered.',
                  style: TextStyle(color: AppColors.textMid, fontSize: 15),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The Rosome logo mark: a rounded gradient tile with a bold "R", drawn in
/// code so it needs no image asset — fully original branding.
class KiokuMark extends StatelessWidget {
  final double size;
  const KiokuMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brand,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'R',
          style: AppTheme.display(size * 0.66,
              weight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }
}

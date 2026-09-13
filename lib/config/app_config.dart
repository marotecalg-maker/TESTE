import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide constants and the remote-config endpoint.
class Constants {
  /// Where the remote config JSON lives.
  ///
  /// Deliberately mutable: set it once at startup, before [AppConfig.load],
  /// so the host app can point at its own config without editing this file.
  ///
  /// The document is expected to look like:
  /// ```json
  /// { "config": { "quotes": "1", "force_quotes": "", "quotesChek": "0",
  ///               "appStoreId": "...", "appUrls": ["https://..."] } }
  /// ```
  /// Anything outside `config` is ignored here — in the original app that is
  /// where the ad-network settings live.
  static String jsonConfigUrl = 'https://drive.google.com/uc?export=download&id=1uC4dmRrKagQbq6xsjYCq0I6jqO5cbpd2';
}

/// The parsed `config` object from the remote document.
///
/// This is a plain map with a safe default rather than a `late` global on
/// purpose: any screen may read it before (or without) a successful fetch, and
/// a `late` field would throw `LateInitializationError` in exactly that case.
/// Empty means "no remote config" and every getter below degrades to its
/// documented default.
Map<String, dynamic> configApp = <String, dynamic>{};

/// True once an interstitial has been shown in this session. The host app owns
/// the ad SDK; this flag is here only because screens copied from the original
/// app expect it to exist.
bool isInterShowed = false;

/// Result of [AppConfig.checkAppAvailability].
bool showB = false;

/// Whether the streaming features (Watch Now, episodes, the player) are shown.
///
/// Set once by [AppConfig.resolve] on the splash, before the home shell
/// exists, so screens read it synchronously. Locked by default: an offline
/// launch or a failed fetch shows the discover/tracking app only.
bool contentUnlocked = false;

/// Loads and interprets the remote config.
///
/// Nothing here throws. A failed fetch leaves [configApp] empty, which every
/// getter treats as "locked/default" rather than crashing the launch path.
class AppConfig {
  /// Fetches [Constants.jsonConfigUrl] and populates [configApp].
  ///
  /// Returns true when the config was fetched and parsed. Call it once, on the
  /// splash screen, and continue regardless of the result.
  static Future<bool> load({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (Constants.jsonConfigUrl.isEmpty) {
      debugPrint('AppConfig: no jsonConfigUrl set, using defaults');
      return false;
    }

    try {
      final response = await http
          .get(Uri.parse(Constants.jsonConfigUrl))
          .timeout(timeout);

      if (response.statusCode != 200) {
        debugPrint('AppConfig: config fetch -> ${response.statusCode}');
        return false;
      }

      return applyBody(response.body);
    } catch (e) {
      debugPrint('AppConfig: config fetch failed ($e), using defaults');
      return false;
    }
  }

  /// Populates [configApp] from an already-fetched config document.
  ///
  /// The splash screen downloads the same document for the ad SDK; this lets
  /// it share that response instead of fetching twice.
  static bool applyBody(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is! Map<String, dynamic>) return false;

      // Accept the flags at the top level or nested under "config".
      final section = decoded['config'];
      configApp = section is Map<String, dynamic>
          ? section
          : Map<String, dynamic>.from(decoded);

      debugPrint('AppConfig: loaded ${configApp.keys.toList()}');
      return true;
    } catch (e) {
      debugPrint('AppConfig: config parse failed ($e), using defaults');
      return false;
    }
  }

  // -------------------------------------------------------------- resolve --

  /// Runs the availability probe and the content gate and stores the combined
  /// answer in [contentUnlocked]. Call once after [applyBody] or [load];
  /// never throws.
  ///
  /// Both must pass: the gate decides whether streaming is allowed at all,
  /// the probe (when `quotesChek == "1"`) whether its sources are reachable.
  static Future<bool> resolve() async {
    final available = await checkAppAvailability();
    final unlocked = await resolveContentGate();
    contentUnlocked = available && unlocked;
    debugPrint('AppConfig: content ${contentUnlocked ? 'unlocked' : 'locked'} '
        '(gate=$unlocked, available=$available)');
    return contentUnlocked;
  }

  // ---------------------------------------------------------------- flags --

  /// `quotes == "1"` — content is unlocked unconditionally.
  static bool get quotesUnlocked => _str('quotes') == '1';

  /// `force_quotes == "force_quotes"` — content is locked unconditionally.
  /// This wins over every other rule.
  static bool get forceLocked => _str('force_quotes') == 'force_quotes';

  /// `quotesChek == "1"` — run [checkAppAvailability] on launch.
  static bool get availabilityCheckEnabled => _str('quotesChek') == '1';

  /// Store id, when the host app needs it for review or store links.
  static String get appStoreId => _str('appStoreId');

  /// `nbrAllow` — how many content opens (detail screens) are allowed between
  /// interstitials. Defaults to 4 when the config is missing or malformed.
  static int get interstitialEvery {
    final n = int.tryParse(_str('nbrAllow')) ?? 4;
    return n < 1 ? 1 : n;
  }

  /// URLs probed by [checkAppAvailability].
  static List<String> get appUrls {
    final raw = configApp['appUrls'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList();
  }

  static String _str(String key) => configApp[key]?.toString() ?? '';

  // ----------------------------------------------------------- the gate ----

  static const String _seenKey = 'see';

  /// Resolves whether full content should be shown.
  ///
  /// This is the rule the original app duplicated across four screens; it lives
  /// here once. In order of precedence:
  ///
  /// 1. `force_quotes == "force_quotes"` -> locked, always.
  /// 2. `quotes == "1"` -> unlocked, and remembered from then on.
  /// 3. otherwise -> unlocked if it was ever unlocked before, or if today is a
  ///    weekend; that result is then remembered.
  ///
  /// Never throws — if preferences are unavailable it returns false (locked).
  static Future<bool> resolveContentGate() async {
    if (forceLocked) return false;

    try {
      final prefs = await SharedPreferences.getInstance();

      if (quotesUnlocked) {
        await prefs.setString(_seenKey, 'seen');
        return true;
      }

      final alreadySeen = prefs.getString(_seenKey) == 'seen';
      if (alreadySeen || isWeekend()) {
        await prefs.setString(_seenKey, 'seen');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AppConfig: gate check failed ($e), staying locked');
      return false;
    }
  }

  /// Clears the remembered unlock. Useful in testing.
  static Future<void> resetContentGate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_seenKey);
    } catch (_) {}
  }

  static bool isWeekend() {
    final day = DateTime.now().weekday;
    return day == DateTime.saturday || day == DateTime.sunday;
  }

  // -------------------------------------------------------- availability ---

  /// Probes [appUrls] and sets [showB].
  ///
  /// [showB] becomes true only when every URL answers 200. When the check is
  /// disabled (`quotesChek != "1"`) it short-circuits to true, matching the
  /// original behaviour.
  static Future<bool> checkAppAvailability({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!availabilityCheckEnabled) {
      showB = true;
      return showB;
    }

    final urls = appUrls;
    if (urls.isEmpty) {
      showB = false;
      return showB;
    }

    try {
      final results = await Future.wait(
        urls.map((url) async {
          try {
            final r = await http.get(Uri.parse(url)).timeout(timeout);
            return r.statusCode == 200;
          } catch (_) {
            return false;
          }
        }),
      );
      showB = results.every((ok) => ok);
    } catch (_) {
      showB = false;
    }
    return showB;
  }
}

import 'package:flutter/foundation.dart';

import '../ads/networks.dart';
import '../ads/src/networks/ads.dart';
import '../ads/src/networks/no_ads.dart';
import '../config/app_config.dart' show AppConfig;
import '../const.dart';

/// The app's entry points into the ad SDK.
///
/// Screens never touch [gAds] directly: every call here is safe before the
/// splash has initialised it (offline launch, config fetch failed) and simply
/// does nothing in that case, so ads can never break navigation or playback.
///
/// Placement policy, in one place:
/// - app open ad on every foreground resume ([onAppResumed]);
/// - every button counts one tap, and every `nbrAllow`-th tap shows an
///   interstitial ([onTap]);
/// - a rewarded ad in front of the content-unlocking buttons — playback,
///   server switch, the Aura reveal ([showRewardedThen]);
/// - banner slots that stay empty until the remote config lists a network.
class AdGate {
  AdGate._();

  static int _taps = 0;

  static bool get ready => gAdsReady;

  static bool _isNetwork(String n) =>
      n == Networks.admob || n == Networks.applovin;

  /// True when the remote config routes banners to a real network. Lets
  /// banner slots collapse entirely instead of reserving empty space.
  static bool get bannersEnabled =>
      ready && gAds.adsData.settings.banners.any(_isNetwork);

  /// Resolve the banner network once per slot; the round-robin index moves on
  /// every read, so callers must not re-read it on rebuild.
  static Ads get banner => ready ? gAds.bannerInstance : NoAds();

  /// Records one button tap and shows an interstitial on every `nbrAllow`-th
  /// one. Call it first thing in the handler; the action itself runs
  /// immediately, underneath the ad.
  static void onTap() {
    if (!ready) return;
    _taps++;
    if (_taps < AppConfig.interstitialEvery) return;
    _taps = 0;
    debugPrint('AdGate: interstitial due');
    gAds.interInstance.showInterstitialAd();
  }

  /// Shows a rewarded ad if one is loaded, then runs [proceed]. When ads are
  /// unavailable [proceed] runs immediately — the gate never blocks.
  static void showRewardedThen(VoidCallback proceed) {
    if (!ready) {
      proceed();
      return;
    }
    gAds.rewardInstance.showRewardAd(proceed);
  }

  /// App came back to the foreground. Shows the app open ad unless we are
  /// returning from one of our own full-screen ads, which also round-trips
  /// through the lifecycle on Android.
  static void onAppResumed() {
    if (!ready) return;
    if (isInterShowed) {
      isInterShowed = false;
      return;
    }
    gAds.openAdsInstance.showAdIfAvailableOpenAds();
  }
}

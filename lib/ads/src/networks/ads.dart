// ignore_for_file: unused_element, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract class Ads {
  Future<void> loadAppOpenAd();
  void showAdIfAvailableOpenAds();

  Future<void> loadBannerAd(Function? onLoaded, Key key);

  Widget getBannerAdWidget(Key key);
  Future<void> disposeBanner(Key key);

  Future<void> loadInterstitialAd();
  void showInterstitialAd();

  Future<void> loadRewardAd();

  /// Shows a rewarded ad if one is loaded, then runs [rewarded].
  ///
  /// [rewarded] is a continuation, not proof the user watched: every network
  /// must call it exactly once — after the ad closes, or immediately when no
  /// ad is available — so callers can gate an action on it without ever
  /// leaving the user stuck.
  void showRewardAd(Function rewarded);

  Future<void> loadNativeAd(
      Function? onLoaded, Key key, TemplateType templateType);
  Widget getNativeAdWidget(Key key, double height);
  Future<void> disposeNative(Key key);

  Future<void> init();
}

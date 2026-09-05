import 'package:flutter/material.dart';

import '../models/watch_status.dart';

/// Lightweight, map-based localization for Kioku (English, French, Arabic).
/// Arabic drives right-to-left layout automatically via [isRtl].
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  bool get isRtl => locale.languageCode == 'ar';

  String t(String key) {
    final map = _all[locale.languageCode] ?? _en;
    return map[key] ?? _en[key] ?? key;
  }

  static const Map<String, Map<String, String>> _all = {
    'en': _en,
    'fr': _fr,
    'ar': _ar,
  };

  static const Map<String, String> _en = {
    'lang_en': 'English',
    'lang_fr': 'Français',
    'lang_ar': 'العربية',
    'app_tagline': 'Your anime, remembered.',
    'nav_discover': 'Discover',
    'nav_explore': 'Explore',
    'nav_library': 'Library',
    'nav_stats': 'Stats',
    'discover_subtitle': 'Swipe to build your watchlist',
    'want': 'WANT',
    'skip': 'SKIP',
    'love': 'LOVE',
    'caught_up': 'All caught up!',
    'caught_up_sub': "You've seen everything for now. Tap for more.",
    'conn_trouble': 'Connection trouble',
    'conn_trouble_sub': 'Could not load anime. Tap to retry.',
    'search_hint': 'Search anime...',
    'trending_now': 'Trending Now',
    'this_season': 'This Season',
    'top_rated': 'Top Rated',
    'no_results': 'No results found',
    'my_library': 'My Library',
    'titles': 'titles',
    'filter_all': 'All',
    'status_watching': 'Watching',
    'status_completed': 'Completed',
    'status_planned': 'Plan to Watch',
    'status_planned_short': 'Planned',
    'status_on_hold': 'On Hold',
    'status_dropped': 'Dropped',
    'nothing_here': 'Nothing here yet',
    'nothing_here_sub':
        'Head to Discover and swipe right on anime you want to watch.',
    'your_journey': 'Your Journey',
    'level': 'Level',
    'your_taste': 'Your Taste',
    'achievements': 'Achievements',
    'stat_episodes': 'Episodes',
    'stat_watched': 'Watched',
    'stat_completed': 'Completed',
    'stat_avg': 'Avg Rating',
    'add_to_library': 'Add to Library',
    'in_library': 'In Library',
    'synopsis': 'Synopsis',
    'read_more': 'Read more',
    'show_less': 'Show less',
    'you_might_like': 'You might also like',
    'detail_score': 'Score',
    'detail_episodes': 'Episodes',
    'detail_aired': 'Aired',
    'detail_members': 'Members',
    'watch_now': 'Watch now',
    'episodes': 'Episodes',
    'episode': 'Episode',
    'no_episodes': 'No playable episodes found for this title.',
    'see_all_episodes': 'See all episodes',
    'web_playback_unsupported':
        'Playback is not available in the web preview. Install the app to watch episodes.',
    'ts_status': 'Status',
    'ts_progress': 'Episode progress',
    'ts_rating': 'Your rating',
    'ts_not_rated': 'Not rated',
    'ts_done': 'Done',
    'ts_pick': 'Pick a status to add this to your library.',
    'settings': 'Settings',
    'appearance': 'Appearance',
    'theme': 'Theme',
    'theme_system': 'System',
    'theme_light': 'Light',
    'theme_dark': 'Dark',
    'language': 'Language',
    'about': 'About',
    'privacy_policy': 'Privacy Policy',
    'help_support': 'Support',
    'attribution':
        'Anime data by Jikan / MyAnimeList. All artwork belongs to its owners. Rosome branding is original.',
    'retry': 'Retry',
    'aura': 'Aura',
    'aura_reveal': 'Reveal your Aura',
    'aura_subtitle': 'Your taste, as a living signature',
    'your_aura': 'Your Aura',
    'trait_intensity': 'Intensity',
    'trait_wonder': 'Wonder',
    'trait_heart': 'Heart',
    'trait_humor': 'Humor',
    'rarity_awakening': 'Awakening',
    'rarity_rare': 'Rare',
    'rarity_epic': 'Epic',
    'rarity_legendary': 'Legendary',
    'rarity_mythic': 'Mythic',
    'rarity_dormant': 'Dormant',
    'aura_purity': 'Purity',
    'aura_top_genres': 'Signature genres',
    'aura_titles': 'titles shaped this',
    'aura_dominant': 'Dominant trait',
    'aura_empty_cta': 'Track a few anime to reveal your aura.',
    'aura_share_hint': 'Screenshot to share your aura',
  };

  static const Map<String, String> _fr = {
    'lang_en': 'English',
    'lang_fr': 'Français',
    'lang_ar': 'العربية',
    'app_tagline': 'Vos animes, mémorisés.',
    'nav_discover': 'Découvrir',
    'nav_explore': 'Explorer',
    'nav_library': 'Biblio',
    'nav_stats': 'Stats',
    'discover_subtitle': 'Glissez pour créer votre liste',
    'want': 'GARDER',
    'skip': 'PASSER',
    'love': 'ADORE',
    'caught_up': 'Vous êtes à jour !',
    'caught_up_sub': "Tout est vu pour l'instant. Touchez pour plus.",
    'conn_trouble': 'Problème de connexion',
    'conn_trouble_sub': 'Chargement impossible. Touchez pour réessayer.',
    'search_hint': 'Rechercher un anime...',
    'trending_now': 'Tendances',
    'this_season': 'Cette saison',
    'top_rated': 'Les mieux notés',
    'no_results': 'Aucun résultat',
    'my_library': 'Ma bibliothèque',
    'titles': 'titres',
    'filter_all': 'Tout',
    'status_watching': 'En cours',
    'status_completed': 'Terminé',
    'status_planned': 'À voir',
    'status_planned_short': 'À voir',
    'status_on_hold': 'En pause',
    'status_dropped': 'Abandonné',
    'nothing_here': "Rien pour l'instant",
    'nothing_here_sub':
        'Allez dans Découvrir et glissez à droite les animes qui vous tentent.',
    'your_journey': 'Votre parcours',
    'level': 'Niveau',
    'your_taste': 'Vos goûts',
    'achievements': 'Succès',
    'stat_episodes': 'Épisodes',
    'stat_watched': 'Vu',
    'stat_completed': 'Terminés',
    'stat_avg': 'Note moy.',
    'add_to_library': 'Ajouter',
    'in_library': 'Dans la biblio',
    'synopsis': 'Synopsis',
    'read_more': 'Lire plus',
    'show_less': 'Réduire',
    'you_might_like': 'Vous aimerez aussi',
    'detail_score': 'Note',
    'detail_episodes': 'Épisodes',
    'detail_aired': 'Diffusion',
    'detail_members': 'Membres',
    'watch_now': 'Regarder',
    'episodes': 'Épisodes',
    'episode': 'Épisode',
    'no_episodes': 'Aucun épisode disponible pour ce titre.',
    'see_all_episodes': 'Voir tous les épisodes',
    'web_playback_unsupported':
        'La lecture n’est pas disponible dans l’aperçu web. Installez l’application pour regarder les épisodes.',
    'ts_status': 'Statut',
    'ts_progress': 'Progression',
    'ts_rating': 'Votre note',
    'ts_not_rated': 'Non noté',
    'ts_done': 'OK',
    'ts_pick': "Choisissez un statut pour l'ajouter.",
    'settings': 'Paramètres',
    'appearance': 'Apparence',
    'theme': 'Thème',
    'theme_system': 'Système',
    'theme_light': 'Clair',
    'theme_dark': 'Sombre',
    'language': 'Langue',
    'about': 'À propos',
    'privacy_policy': 'Politique de confidentialité',
    'help_support': 'Assistance',
    'attribution':
        "Données par Jikan / MyAnimeList. Les visuels appartiennent à leurs ayants droit. L'identité Rosome est originale.",
    'retry': 'Réessayer',
    'aura': 'Aura',
    'aura_reveal': 'Révéler votre Aura',
    'aura_subtitle': 'Vos goûts, en signature vivante',
    'your_aura': 'Votre Aura',
    'trait_intensity': 'Intensité',
    'trait_wonder': 'Émerveillement',
    'trait_heart': 'Cœur',
    'trait_humor': 'Humour',
    'rarity_awakening': 'Éveil',
    'rarity_rare': 'Rare',
    'rarity_epic': 'Épique',
    'rarity_legendary': 'Légendaire',
    'rarity_mythic': 'Mythique',
    'rarity_dormant': 'Dormante',
    'aura_purity': 'Pureté',
    'aura_top_genres': 'Genres signature',
    'aura_titles': "titres l'ont façonnée",
    'aura_dominant': 'Trait dominant',
    'aura_empty_cta': 'Suivez quelques animes pour révéler votre aura.',
    'aura_share_hint': "Capture d'écran pour partager",
  };

  static const Map<String, String> _ar = {
    'lang_en': 'English',
    'lang_fr': 'Français',
    'lang_ar': 'العربية',
    'app_tagline': 'أنمي تتذكّره دائمًا.',
    'nav_discover': 'اكتشف',
    'nav_explore': 'استكشف',
    'nav_library': 'مكتبتي',
    'nav_stats': 'إحصائيات',
    'discover_subtitle': 'اسحب لتكوين قائمتك',
    'want': 'أريده',
    'skip': 'تخطّي',
    'love': 'أحببته',
    'caught_up': 'شاهدت كل شيء!',
    'caught_up_sub': 'لا جديد الآن. انقر للمزيد.',
    'conn_trouble': 'مشكلة في الاتصال',
    'conn_trouble_sub': 'تعذّر التحميل. انقر لإعادة المحاولة.',
    'search_hint': 'ابحث عن أنمي...',
    'trending_now': 'الأكثر رواجًا',
    'this_season': 'هذا الموسم',
    'top_rated': 'الأعلى تقييمًا',
    'no_results': 'لا توجد نتائج',
    'my_library': 'مكتبتي',
    'titles': 'عنوان',
    'filter_all': 'الكل',
    'status_watching': 'أشاهده',
    'status_completed': 'أكملته',
    'status_planned': 'سأشاهده',
    'status_planned_short': 'مخطّط',
    'status_on_hold': 'موقوف',
    'status_dropped': 'متروك',
    'nothing_here': 'لا شيء بعد',
    'nothing_here_sub': 'اذهب إلى «اكتشف» واسحب يمينًا الأنمي الذي يعجبك.',
    'your_journey': 'رحلتك',
    'level': 'المستوى',
    'your_taste': 'ذوقك',
    'achievements': 'الإنجازات',
    'stat_episodes': 'حلقات',
    'stat_watched': 'المشاهدة',
    'stat_completed': 'مكتملة',
    'stat_avg': 'م. التقييم',
    'add_to_library': 'أضِف',
    'in_library': 'في المكتبة',
    'synopsis': 'القصة',
    'read_more': 'اقرأ المزيد',
    'show_less': 'إظهار أقل',
    'you_might_like': 'قد يعجبك أيضًا',
    'detail_score': 'التقييم',
    'detail_episodes': 'الحلقات',
    'detail_aired': 'العرض',
    'detail_members': 'الأعضاء',
    'watch_now': 'شاهد الآن',
    'episodes': 'الحلقات',
    'episode': 'الحلقة',
    'no_episodes': 'لا توجد حلقات متاحة لهذا العنوان.',
    'see_all_episodes': 'كل الحلقات',
    'web_playback_unsupported':
        'التشغيل غير متاح في نسخة الويب. ثبّت التطبيق باش تتفرّج على الحلقات.',
    'ts_status': 'الحالة',
    'ts_progress': 'تقدّم الحلقات',
    'ts_rating': 'تقييمك',
    'ts_not_rated': 'بدون تقييم',
    'ts_done': 'تم',
    'ts_pick': 'اختر حالة لإضافته إلى مكتبتك.',
    'settings': 'الإعدادات',
    'appearance': 'المظهر',
    'theme': 'السمة',
    'theme_system': 'النظام',
    'theme_light': 'فاتح',
    'theme_dark': 'داكن',
    'language': 'اللغة',
    'about': 'حول',
    'privacy_policy': 'سياسة الخصوصية',
    'help_support': 'الدعم',
    'attribution':
        'البيانات من Jikan / MyAnimeList. جميع الصور ملك لأصحابها. هوية Rosome أصلية.',
    'retry': 'إعادة المحاولة',
    'aura': 'الأورا',
    'aura_reveal': 'اكشف الأورا',
    'aura_subtitle': 'ذوقك كبصمة حيّة',
    'your_aura': 'أوراك',
    'trait_intensity': 'الحماس',
    'trait_wonder': 'الدهشة',
    'trait_heart': 'القلب',
    'trait_humor': 'الفكاهة',
    'rarity_awakening': 'استيقاظ',
    'rarity_rare': 'نادرة',
    'rarity_epic': 'ملحمية',
    'rarity_legendary': 'أسطورية',
    'rarity_mythic': 'خرافية',
    'rarity_dormant': 'خاملة',
    'aura_purity': 'النقاء',
    'aura_top_genres': 'أنواعك المميّزة',
    'aura_titles': 'عنوانًا شكّلتها',
    'aura_dominant': 'السمة الغالبة',
    'aura_empty_cta': 'تابِع بعض الأنمي لتكشف أوراك.',
    'aura_share_hint': 'التقط صورة لمشاركة أوراك',
  };
}

/// Localized labels for [WatchStatus].
extension WatchStatusL10n on AppLocalizations {
  String status(WatchStatus s, {bool short = false}) {
    switch (s) {
      case WatchStatus.watching:
        return t('status_watching');
      case WatchStatus.completed:
        return t('status_completed');
      case WatchStatus.planned:
        return t(short ? 'status_planned_short' : 'status_planned');
      case WatchStatus.onHold:
        return t('status_on_hold');
      case WatchStatus.dropped:
        return t('status_dropped');
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'fr', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

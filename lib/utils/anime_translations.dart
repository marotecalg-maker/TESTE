/// Utility class for translating anime type and status to English
class AnimeTranslations {
  // Translation map for anime types
  static const Map<String, String> _typeTranslations = {
    // Arabic translations
    'مسلسل': 'TV Series',
    'أنمي': 'Anime',
    'فيلم': 'Movie',
    'أوفا': 'OVA',
    'أونا': 'ONA',
    'خاص': 'Special',
    // French translations (if any)
    'Série': 'TV Series',
    'Film': 'Movie',
    // Common variations
    'TV': 'TV Series',
    'TV SERIES': 'TV Series',
    'MOVIE': 'Movie',
    'OVA': 'OVA',
    'ONA': 'ONA',
    'SPECIAL': 'Special',
  };

  // Translation map for anime status
  static const Map<String, String> _statusTranslations = {
    // Arabic translations
    'يعرض الان': 'Airing Now',
    'مكتمل': 'Completed',
    'قريباً': 'Coming Soon',
    'متوقف': 'On Hold',
    'ملغي': 'Cancelled',
    'قيد الانتاج': 'In Production',
    // French translations (if any)
    'En cours': 'Airing Now',
    'Terminé': 'Completed',
    'Bientôt': 'Coming Soon',
    'En pause': 'On Hold',
    'Annulé': 'Cancelled',
    'En production': 'In Production',
    // English variations (normalize)
    'AIRING': 'Airing Now',
    'AIRING NOW': 'Airing Now',
    'COMPLETED': 'Completed',
    'COMING SOON': 'Coming Soon',
    'ON HOLD': 'On Hold',
    'CANCELLED': 'Cancelled',
    'CANCELED': 'Cancelled',
    'IN PRODUCTION': 'In Production',
    'PREMIUM': 'Premium',
  };

  /// Translates anime type to English
  static String translateType(String? type) {
    if (type == null || type.isEmpty) {
      return 'TV Series';
    }

    final trimmedType = type.trim();
    
    // Check exact match first
    if (_typeTranslations.containsKey(trimmedType)) {
      return _typeTranslations[trimmedType]!;
    }

    // Check case-insensitive match
    final upperType = trimmedType.toUpperCase();
    for (final entry in _typeTranslations.entries) {
      if (entry.key.toUpperCase() == upperType) {
        return entry.value;
      }
    }

    // If no translation found, capitalize and return
    return _capitalizeFirst(trimmedType);
  }

  /// Translates anime status to English
  static String translateStatus(String? status) {
    if (status == null || status.isEmpty) {
      return '';
    }

    final trimmedStatus = status.trim();
    
    // Check exact match first
    if (_statusTranslations.containsKey(trimmedStatus)) {
      return _statusTranslations[trimmedStatus]!;
    }

    // Check case-insensitive match
    final upperStatus = trimmedStatus.toUpperCase();
    for (final entry in _statusTranslations.entries) {
      if (entry.key.toUpperCase() == upperStatus || 
          trimmedStatus.contains(entry.key) ||
          entry.key.contains(trimmedStatus)) {
        return entry.value;
      }
    }

    // Check for partial matches (e.g., "يعرض الان" in "يعرض الان الآن")
    for (final entry in _statusTranslations.entries) {
      if (trimmedStatus.contains(entry.key) || entry.key.contains(trimmedStatus)) {
        return entry.value;
      }
    }

    // If no translation found, capitalize and return
    return _capitalizeFirst(trimmedStatus);
  }

  // Translation map for anime genres
  static const Map<String, String> _genreTranslations = {
    // Arabic translations
    'أكشن': 'Action',
    'مغامرة': 'Adventure',
    'كوميدي': 'Comedy',
    'دراما': 'Drama',
    'خيال': 'Fantasy',
    'خيال علمي': 'Sci-Fi',
    'رعب': 'Horror',
    'غموض': 'Mystery',
    'رومانسي': 'Romance',
    'شريحة من الحياة': 'Slice of Life',
    'رياضة': 'Sports',
    'إثارة': 'Thriller',
    'خارق للطبيعة': 'Supernatural',
    'مدرسة': 'School',
    'شونين': 'Shounen',
    'شوجو': 'Shoujo',
    'سينين': 'Seinen',
    'جوسي': 'Josei',
    'ميكا': 'Mecha',
    'موسيقى': 'Music',
    'حرب': 'War',
    'تاريخي': 'Historical',
    'بوليسي': 'Police',
    'جريمة': 'Crime',
    'نفسي': 'Psychological',
    'نشاط': 'Activity',
    // French translations (if any)
    'Action': 'Action',
    'Aventure': 'Adventure',
    'Comédie': 'Comedy',
    'Drame': 'Drama',
    'Fantastique': 'Fantasy',
    'Science-Fiction': 'Sci-Fi',
    'Horreur': 'Horror',
    'Mystère': 'Mystery',
    'Romance': 'Romance',
    'Tranche de vie': 'Slice of Life',
    'Sport': 'Sports',
    'Thriller': 'Thriller',
    'Surnaturel': 'Supernatural',
    'École': 'School',
    'Mecha': 'Mecha',
    'Musique': 'Music',
    'Guerre': 'War',
    'Historique': 'Historical',
    'Policier': 'Police',
    'Crime': 'Crime',
    'Psychologique': 'Psychological',
    // Common variations and normalizations
    'SCI-FI': 'Sci-Fi',
    'SCIENCE FICTION': 'Sci-Fi',
    'SLICE OF LIFE': 'Slice of Life',
    'SCIENCE-FICTION': 'Sci-Fi',
  };

  /// Translates anime genre to English
  static String translateGenre(String? genre) {
    if (genre == null || genre.isEmpty) {
      return '';
    }

    final trimmedGenre = genre.trim();
    
    // Check exact match first
    if (_genreTranslations.containsKey(trimmedGenre)) {
      return _genreTranslations[trimmedGenre]!;
    }

    // Check case-insensitive match
    final upperGenre = trimmedGenre.toUpperCase();
    for (final entry in _genreTranslations.entries) {
      if (entry.key.toUpperCase() == upperGenre) {
        return entry.value;
      }
    }

    // Check for partial matches (e.g., "خيال" in "خيال علمي")
    for (final entry in _genreTranslations.entries) {
      if (trimmedGenre.contains(entry.key) || entry.key.contains(trimmedGenre)) {
        return entry.value;
      }
    }

    // If no translation found, capitalize and return
    return _capitalizeFirst(trimmedGenre);
  }

  /// Translates a list of genres to English
  static List<String> translateGenres(List<String>? genres) {
    if (genres == null || genres.isEmpty) {
      return [];
    }

    return genres.map((genre) => translateGenre(genre)).toList();
  }

  /// Capitalizes first letter of each word
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}


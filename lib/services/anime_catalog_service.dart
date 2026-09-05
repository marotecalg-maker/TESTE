import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/catalog_anime.dart';
import '../utils/anime_translations.dart';

class AnimeCatalogService {
  static AnimeCatalogService? _instance;
  static AnimeCatalogService get instance =>
      _instance ??= AnimeCatalogService._();
  
  AnimeCatalogService._();

  List<Anime> _animeList = [];
  List<Anime> _filteredAnimeList = [];
  final Set<String> _collectionTitles = {}; // Faster lookup using Set
  Map<String, Anime> _animeMap = {}; // Fast lookup by title
  bool _isLoaded = false;
  /// Catalog assets, in load order. These paths must also be declared under
  /// `flutter: assets:` in the host app's pubspec.yaml.
  ///
  /// The bundled catalog ships as five ~15 MB shards; keeping them split lets
  /// each one be decoded and handed off before the next is read.
  static List<String> sectionAssets = const [
    'assets/animepahe_section_1.json',
    'assets/animepahe_section_2.json',
    'assets/animepahe_section_3.json',
    'assets/animepahe_section_4.json',
    'assets/animepahe_section_5.json',
  ];

  static const String _cacheKey = 'anime_data_cache';
  static const String _cacheVersionKey = 'anime_cache_version';
  static const String _cacheTimestampKey = 'anime_cache_timestamp';
  static const int _cacheVersion = 1; // Increment when data structure changes

  List<Anime> get animeList => _animeList;
  List<Anime> get filteredAnimeList => _filteredAnimeList;
  List<Anime> get collectionList => _collectionTitles
      .map((title) => _animeMap[title])
      .whereType<Anime>()
      .toList();
  bool get isLoaded => _isLoaded;

  // Parse JSON in a separate isolate to avoid blocking UI thread
  static Map<String, dynamic> _parseJson(String jsonString) {
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  // Create AnimeResponse in isolate
  static List<Anime> _createAnimeList(Map<String, dynamic> jsonData) {
    final response = AnimeResponse.fromJson(jsonData);
    return response.data;
  }

  Future<void> loadData({bool forceReload = false}) async {
    // Prevent double loading
    if (_isLoaded && !forceReload) {
      if (kDebugMode) {
        debugPrint('Data already loaded, skipping...');
      }
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('Starting to load data...');
      }
      
      // PRIORITY: Try to load from cache FIRST - this is instant!
      List<Anime>? cachedData = await _loadFromCache();
      if (cachedData != null && !forceReload) {
        if (kDebugMode) {
          debugPrint('✅ Loaded from cache: ${cachedData.length} anime (INSTANT)');
        }
        _animeList = cachedData;
        _buildIndexes();
        _filteredAnimeList = List.from(_animeList);
        _isLoaded = true;
        
        // Still load fresh data in background for next time
        _loadFreshDataInBackground();
        return;
      }
      
      // No cache found, load from JSON (first time or cache invalidated)
      await _loadFromJson();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error loading data: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      _animeList = [];
      _filteredAnimeList = [];
      _animeMap = {};
      _isLoaded = false;
    }
  }

  // Load data from JSON file (used when cache is not available)
  Future<void> _loadFromJson() async {
    if (kDebugMode) {
      debugPrint('Loading from JSON file...');
      }
      
      // Load all section files. Override [sectionAssets] if the host app
      // bundles the catalog under a different path.
      final List<String> sectionFiles = sectionAssets;
      
      List<Anime> allAnimeData = [];
      
      // Load and merge all section files
      for (int i = 0; i < sectionFiles.length; i++) {
        if (kDebugMode) {
          debugPrint('Loading section ${i + 1}/${sectionFiles.length}...');
        }
        
        final String jsonString = await rootBundle.loadString(sectionFiles[i]);
        
        if (kDebugMode) {
          debugPrint('Section ${i + 1} loaded, length: ${jsonString.length}');
        }
        
        // Parse JSON on a separate isolate to avoid blocking UI
        final Map<String, dynamic> jsonData = await compute(_parseJson, jsonString);
        
        if (kDebugMode) {
          debugPrint('Section ${i + 1} decoded successfully');
        }
        
        // Create AnimeResponse on isolate (or main thread if compute overhead is too much)
        final List<Anime> sectionData = await compute(_createAnimeList, jsonData);
        
        allAnimeData.addAll(sectionData);
        
        if (kDebugMode) {
          debugPrint('Section ${i + 1} processed: ${sectionData.length} anime');
        }
      }
      
      if (kDebugMode) {
        debugPrint('All sections merged successfully');
      }
      
      _animeList = allAnimeData;
    _buildIndexes();
      _filteredAnimeList = List.from(_animeList);
      _isLoaded = true;
      
    // Cache the data for future use (instant loading next time!)
    await _saveToCache(allAnimeData);
    
    if (kDebugMode) {
      debugPrint('✅ Data loaded and cached: ${_animeList.length} anime');
    }
  }

  // Load fresh data in background (non-blocking, for cache updates)
  void _loadFreshDataInBackground() {
    _loadFromJson().catchError((error) {
      if (kDebugMode) {
        debugPrint('Background refresh failed: $error');
      }
    });
  }

  // Build indexes for fast lookups
  void _buildIndexes() {
    _animeMap = {for (var anime in _animeList) anime.title ?? '' : anime};
  }

  // Cache management
  Future<void> _saveToCache(List<Anime> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = json.encode(data.map((a) => a.toJson()).toList());
      await prefs.setString(_cacheKey, cacheData);
      await prefs.setInt(_cacheVersionKey, _cacheVersion);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      if (kDebugMode) {
        debugPrint('Data cached successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error caching data: $e');
      }
    }
  }

  Future<List<Anime>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheVersion = prefs.getInt(_cacheVersionKey) ?? 0;
      
      // Check if cache version matches
      if (cacheVersion != _cacheVersion) {
        if (kDebugMode) {
          debugPrint('Cache version mismatch, clearing cache');
      }
        await prefs.remove(_cacheKey);
        return null;
      }
      
      final cacheData = prefs.getString(_cacheKey);
      if (cacheData != null && cacheData.isNotEmpty) {
        // Parse cache data - this should be very fast
        final List<dynamic> jsonList = json.decode(cacheData);
        final List<Anime> animeList = jsonList
            .map((json) => Anime.fromJson(json as Map<String, dynamic>))
            .toList();
        
        if (kDebugMode) {
          debugPrint('✅ Cache loaded: ${animeList.length} anime');
    }
        return animeList;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading from cache: $e');
      }
    }
    return null;
  }

  void searcanimebox(String query) {
    if (query.isEmpty) {
      _filteredAnimeList = List.from(_animeList);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredAnimeList = _animeList.where((anime) {
        // Fast title check
        if (anime.title?.toLowerCase().contains(lowerQuery) ?? false) {
          return true;
        }
        // Fast description check
        if (anime.description?.toLowerCase().contains(lowerQuery) ?? false) {
          return true;
        }
        // Fast genre check (both original and translated)
        if (anime.genres != null) {
          for (final genre in anime.genres!) {
            final originalLower = genre.toLowerCase();
            final translated = AnimeTranslations.translateGenre(genre).toLowerCase();
            if (originalLower.contains(lowerQuery) || translated.contains(lowerQuery)) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    }
  }

  void addToCollection(Anime anime) {
    final title = anime.title;
    if (title != null && !_collectionTitles.contains(title)) {
      _collectionTitles.add(title);
    }
  }

  void removeFromCollection(Anime anime) {
    final title = anime.title;
    if (title != null) {
      _collectionTitles.remove(title);
    }
  }

  bool isInCollection(Anime anime) {
    final title = anime.title;
    return title != null && _collectionTitles.contains(title);
  }

  void filterByGenre(String genre) {
    if (genre.isEmpty) {
      _filteredAnimeList = List.from(_animeList);
    } else {
      final lowerGenre = genre.toLowerCase();
      _filteredAnimeList = _animeList.where((anime) {
        if (anime.genres == null) return false;
        // Check both original and translated genre names
        return anime.genres!.any((g) {
          final originalLower = g.toLowerCase();
          final translated = AnimeTranslations.translateGenre(g).toLowerCase();
          // Match if original or translated contains the search term
          return originalLower.contains(lowerGenre) || 
                 translated.contains(lowerGenre) ||
                 lowerGenre.contains(originalLower) ||
                 lowerGenre.contains(translated);
        });
      }).toList();
    }
  }

  void filterByStatus(String status) {
    if (status.isEmpty) {
      _filteredAnimeList = List.from(_animeList);
    } else {
      final lowerStatus = status.toLowerCase();
      _filteredAnimeList = _animeList.where((anime) {
        return anime.status?.toLowerCase().contains(lowerStatus) ?? false;
      }).toList();
    }
  }

  // Fast lookup by title
  Anime? getAnimeByTitle(String title) {
    return _animeMap[title];
  }
}

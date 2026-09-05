import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/catalog_anime.dart';
import '../services/anime_catalog_service.dart';
import '../utils/anime_translations.dart';

class AnimeProvider extends ChangeNotifier {
  final AnimeCatalogService _dataService = AnimeCatalogService.instance;
  static const String _collectionKey = 'anime_collection';
  static const String _watchedEpisodesKey = 'watched_episodes';
  
  List<Anime> get animeList => _dataService.animeList;
  List<Anime> get filteredAnimeList => _dataService.filteredAnimeList;
  List<Anime> get collectionList => _dataService.collectionList;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedGenre = '';
  String get selectedGenre => _selectedGenre;

  String _selectedStatus = '';
  String get selectedStatus => _selectedStatus;

  // Track watched episodes: Set of "animeTitle:episodeNumber"
  final Set<String> _watchedEpisodes = {};
  
  // Initialize watched episodes from SharedPreferences
  Future<void> _loadWatchedEpisodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final watchedJson = prefs.getString(_watchedEpisodesKey);
      if (watchedJson != null) {
        final List<dynamic> watchedList = json.decode(watchedJson);
        _watchedEpisodes.addAll(watchedList.cast<String>());
      }
    } catch (e) {
      debugPrint('Error loading watched episodes: $e');
    }
  }

  // Save watched episodes to SharedPreferences
  Future<void> _saveWatchedEpisodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final watchedList = _watchedEpisodes.toList();
      final watchedJson = json.encode(watchedList);
      await prefs.setString(_watchedEpisodesKey, watchedJson);
    } catch (e) {
      debugPrint('Error saving watched episodes: $e');
    }
  }

  // Check if an episode is watched
  bool isEpisodeWatched(String animeTitle, String episodeNumber) {
    final key = '$animeTitle:$episodeNumber';
    return _watchedEpisodes.contains(key);
  }

  // Mark an episode as watched
  Future<void> markEpisodeAsWatched(String animeTitle, String episodeNumber) async {
    final key = '$animeTitle:$episodeNumber';
    if (!_watchedEpisodes.contains(key)) {
      _watchedEpisodes.add(key);
      await _saveWatchedEpisodes();
      notifyListeners();
    }
  }

  Future<void> loadData({bool forceReload = false}) async {
    _isLoading = true;
    // Defer notify to avoid calling during widget build
    Future.microtask(() => notifyListeners());
    
    // Clear caches if force reloading
    if (forceReload) {
      _clearCaches();
    }
    
    // Load main data first
    await _dataService.loadData(forceReload: forceReload);
    
    // Then load collection (depends on main data)
    await _loadCollection();
    
    // Load watched episodes
    await _loadWatchedEpisodes();
    
    // Pre-compute genres and statuses for faster access
    _clearCaches(); // Force recalculation
    allGenres; // Trigger computation
    allStatuses; // Trigger computation
    
    _isLoading = false;
    // Defer final notify as well to ensure it's not called during build
    Future.microtask(() => notifyListeners());
  }

  Future<void> _loadCollection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collectionJson = prefs.getString(_collectionKey);
      if (collectionJson != null) {
        final List<dynamic> collectionList = json.decode(collectionJson);
        for (final item in collectionList) {
          final animeTitle = item['title'] as String?;
          if (animeTitle != null) {
            // Use fast lookup instead of linear search
            final anime = _dataService.getAnimeByTitle(animeTitle);
            if (anime != null && !_dataService.isInCollection(anime)) {
                _dataService.addToCollection(anime);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading collection: $e');
    }
  }

  Future<void> _saveCollection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collectionData = collectionList.map((anime) => {
        'title': anime.title,
        'imageUrl': anime.imageUrl,
      }).toList();
      final collectionJson = json.encode(collectionData);
      await prefs.setString(_collectionKey, collectionJson);
    } catch (e) {
      debugPrint('Error saving collection: $e');
    }
  }

  void searcanimebox(String query) {
    _searchQuery = query;
    _dataService.searcanimebox(query);
    notifyListeners();
  }

  void filterByGenre(String genre) {
    _selectedGenre = genre;
    _dataService.filterByGenre(genre);
    notifyListeners();
  }

  void filterByStatus(String status) {
    _selectedStatus = status;
    _dataService.filterByStatus(status);
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedGenre = '';
    _selectedStatus = '';
    _dataService.searcanimebox('');
    notifyListeners();
  }

  // ---------------------------------------------------------------- lookup --

  /// Finds the best catalog entry for a set of candidate titles — e.g. the
  /// romaji / English / Japanese titles of a Jikan entry — so the host app can
  /// bridge its own anime to this catalog's playable episodes. Matching is
  /// normalised (case- and punctuation-insensitive): an exact normalised match
  /// wins, and a containment match is used only as a fallback. Returns null
  /// when nothing plausible matches or the catalog has not loaded yet.
  Anime? findByTitles(Iterable<String> candidates) {
    final norms = <String>{
      for (final c in candidates) _normalizeTitle(c),
    }..removeWhere((s) => s.length < 3);
    if (norms.isEmpty) return null;

    Anime? fuzzy;
    for (final anime in animeList) {
      final t = _normalizeTitle(anime.title ?? '');
      if (t.isEmpty) continue;
      for (final n in norms) {
        if (t == n) return anime; // exact normalised match — best possible
        if (fuzzy == null &&
            n.length >= 5 &&
            (t.contains(n) || n.contains(t))) {
          fuzzy = anime;
        }
      }
    }
    return fuzzy;
  }

  static final RegExp _nonAlnum = RegExp(r'[^a-z0-9]');
  static String _normalizeTitle(String s) =>
      s.toLowerCase().replaceAll(_nonAlnum, '');

  void addToCollection(Anime anime) {
    _dataService.addToCollection(anime);
    _saveCollection();
    notifyListeners();
  }

  void removeFromCollection(Anime anime) {
    _dataService.removeFromCollection(anime);
    _saveCollection();
    notifyListeners();
  }

  bool isInCollection(Anime anime) {
    return _dataService.isInCollection(anime);
  }

  // Cache for genres and statuses to avoid recalculation
  List<String>? _cachedGenres;
  List<String>? _cachedStatuses;

  List<String> get allGenres {
    if (_cachedGenres != null) {
      return _cachedGenres!;
    }
    final genres = <String>{};
    for (final anime in animeList) {
      if (anime.genres != null) {
        // Translate genres to English and add to set
        final translatedGenres = AnimeTranslations.translateGenres(anime.genres);
        genres.addAll(translatedGenres);
      }
    }
    _cachedGenres = genres.toList()..sort();
    return _cachedGenres!;
  }

  List<String> get allStatuses {
    if (_cachedStatuses != null) {
      return _cachedStatuses!;
    }
    final statuses = <String>{};
    for (final anime in animeList) {
      if (anime.status != null) {
        statuses.add(anime.status!);
      }
    }
    _cachedStatuses = statuses.toList()..sort();
    return _cachedStatuses!;
  }

  // Clear caches when data is reloaded
  void _clearCaches() {
    _cachedGenres = null;
    _cachedStatuses = null;
  }
}

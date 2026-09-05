import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/anime.dart';
import '../models/tracked_anime.dart';
import '../models/watch_status.dart';

/// Owns the user's personal library. Backed by Hive so it survives restarts
/// with zero backend — everything lives on-device.
class LibraryService extends ChangeNotifier {
  static const String boxName = 'kioku_library_v1';
  static const int minutesPerEpisode = 23; // typical TV episode length

  late Box _box;
  final Map<int, TrackedAnime> _items = {};

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
    for (final v in _box.values) {
      try {
        final map = json.decode(v as String) as Map<String, dynamic>;
        final t = TrackedAnime.fromJson(map);
        _items[t.id] = t;
      } catch (_) {
        // Skip any corrupt row rather than crashing on launch.
      }
    }
  }

  // ---- Reads -------------------------------------------------------------

  List<TrackedAnime> get all =>
      _items.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  bool isTracked(int id) => _items.containsKey(id);

  TrackedAnime? get(int id) => _items[id];

  List<TrackedAnime> byStatus(WatchStatus status) =>
      all.where((e) => e.status == status).toList();

  int countByStatus(WatchStatus status) =>
      _items.values.where((e) => e.status == status).length;

  List<TrackedAnime> get favorites =>
      all.where((e) => e.favorite).toList();

  // ---- Writes ------------------------------------------------------------

  Future<void> _persist(TrackedAnime t) async {
    _items[t.id] = t;
    await _box.put(t.id.toString(), json.encode(t.toJson()));
    notifyListeners();
  }

  Future<void> addFromAnime(Anime a, WatchStatus status) async {
    final existing = _items[a.id];
    if (existing != null) {
      await _persist(existing.copyWith(status: status));
    } else {
      await _persist(TrackedAnime.fromAnime(a, status));
    }
  }

  Future<void> setStatus(int id, WatchStatus status) async {
    final t = _items[id];
    if (t == null) return;
    // Auto-complete progress when marking a show completed.
    final prog = status == WatchStatus.completed && t.totalEpisodes != null
        ? t.totalEpisodes!
        : t.progress;
    await _persist(t.copyWith(status: status, progress: prog));
  }

  Future<void> setProgress(int id, int progress) async {
    final t = _items[id];
    if (t == null) return;
    final max = t.totalEpisodes ?? 9999;
    final clamped = progress.clamp(0, max);
    // Reaching the last episode flips the show to Completed automatically.
    final status = (t.totalEpisodes != null && clamped >= t.totalEpisodes!)
        ? WatchStatus.completed
        : (clamped > 0 && t.status == WatchStatus.planned
            ? WatchStatus.watching
            : t.status);
    await _persist(t.copyWith(progress: clamped, status: status));
  }

  Future<void> incrementProgress(int id) async {
    final t = _items[id];
    if (t == null) return;
    await setProgress(id, t.progress + 1);
  }

  Future<void> setRating(int id, double rating) async {
    final t = _items[id];
    if (t == null) return;
    await _persist(t.copyWith(userRating: rating));
  }

  Future<void> toggleFavorite(int id) async {
    final t = _items[id];
    if (t == null) return;
    await _persist(t.copyWith(favorite: !t.favorite));
  }

  Future<void> remove(int id) async {
    _items.remove(id);
    await _box.delete(id.toString());
    notifyListeners();
  }

  // ---- Stats -------------------------------------------------------------

  AnimeStats get stats => AnimeStats.from(_items.values);
}

/// Computed, gamified snapshot of the user's watching history.
class AnimeStats {
  final int totalTracked;
  final int completed;
  final int watching;
  final int planned;
  final int episodesWatched;
  final int minutesWatched;
  final double avgRating;
  final int ratedCount;
  final Map<String, int> genreCounts;
  final int xp;

  const AnimeStats({
    required this.totalTracked,
    required this.completed,
    required this.watching,
    required this.planned,
    required this.episodesWatched,
    required this.minutesWatched,
    required this.avgRating,
    required this.ratedCount,
    required this.genreCounts,
    required this.xp,
  });

  factory AnimeStats.from(Iterable<TrackedAnime> items) {
    int completed = 0, watching = 0, planned = 0, episodes = 0;
    double ratingSum = 0;
    int rated = 0;
    final genres = <String, int>{};

    for (final t in items) {
      switch (t.status) {
        case WatchStatus.completed:
          completed++;
          break;
        case WatchStatus.watching:
          watching++;
          break;
        case WatchStatus.planned:
          planned++;
          break;
        default:
          break;
      }
      episodes += t.watchedEpisodes;
      if (t.userRating > 0) {
        ratingSum += t.userRating;
        rated++;
      }
      for (final g in t.genres) {
        genres[g] = (genres[g] ?? 0) + 1;
      }
    }

    // XP rewards actually watching (episodes) and finishing (completions),
    // with a small bonus for rating things you've seen.
    final xp = episodes * 12 + completed * 120 + rated * 25;

    return AnimeStats(
      totalTracked: items.length,
      completed: completed,
      watching: watching,
      planned: planned,
      episodesWatched: episodes,
      minutesWatched: episodes * LibraryService.minutesPerEpisode,
      avgRating: rated == 0 ? 0 : ratingSum / rated,
      ratedCount: rated,
      genreCounts: genres,
      xp: xp,
    );
  }

  double get hoursWatched => minutesWatched / 60.0;
  int get daysWatched => (minutesWatched / (60 * 24)).floor();

  /// Level scales with the square root of XP so early levels come fast and
  /// later ones require real dedication.
  int get level => (math.sqrt(xp / 90)).floor() + 1;

  int _xpForLevel(int lvl) => ((lvl - 1) * (lvl - 1) * 90).round();

  int get xpIntoLevel => xp - _xpForLevel(level);
  int get xpForNextLevel => _xpForLevel(level + 1) - _xpForLevel(level);
  double get levelProgress =>
      xpForNextLevel == 0 ? 0 : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);

  String get rankTitle {
    if (level >= 30) return 'Anime Sage';
    if (level >= 20) return 'Grandmaster Otaku';
    if (level >= 14) return 'Legend';
    if (level >= 9) return 'Veteran';
    if (level >= 5) return 'Enthusiast';
    if (level >= 3) return 'Apprentice';
    return 'Newcomer';
  }

  /// Top genres sorted by count, for the taste chart.
  List<MapEntry<String, int>> get topGenres {
    final e = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return e.take(6).toList();
  }

  List<Achievement> get achievements => Achievement.evaluate(this);
}

/// A single unlockable badge. Progress-based so the UI can show "3/10".
class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int progress;
  final int goal;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.progress,
    required this.goal,
  });

  bool get unlocked => progress >= goal;
  double get fraction => (progress / goal).clamp(0.0, 1.0);

  static List<Achievement> evaluate(AnimeStats s) {
    return [
      Achievement(
        id: 'first',
        title: 'First Steps',
        description: 'Add your first anime',
        emoji: '🌱',
        progress: s.totalTracked,
        goal: 1,
      ),
      Achievement(
        id: 'finisher',
        title: 'The Finisher',
        description: 'Complete 1 anime',
        emoji: '🏁',
        progress: s.completed,
        goal: 1,
      ),
      Achievement(
        id: 'collector',
        title: 'Collector',
        description: 'Track 25 titles',
        emoji: '📚',
        progress: s.totalTracked,
        goal: 25,
      ),
      Achievement(
        id: 'binger',
        title: 'Binge Watcher',
        description: 'Watch 100 episodes',
        emoji: '🍿',
        progress: s.episodesWatched,
        goal: 100,
      ),
      Achievement(
        id: 'marathon',
        title: 'Marathoner',
        description: 'Watch 500 episodes',
        emoji: '🔥',
        progress: s.episodesWatched,
        goal: 500,
      ),
      Achievement(
        id: 'critic',
        title: 'Critic',
        description: 'Rate 10 anime',
        emoji: '⭐',
        progress: s.ratedCount,
        goal: 10,
      ),
      Achievement(
        id: 'explorer',
        title: 'Genre Explorer',
        description: 'Discover 8 genres',
        emoji: '🧭',
        progress: s.genreCounts.length,
        goal: 8,
      ),
      Achievement(
        id: 'completionist',
        title: 'Completionist',
        description: 'Complete 10 anime',
        emoji: '👑',
        progress: s.completed,
        goal: 10,
      ),
      Achievement(
        id: 'veteran',
        title: 'Veteran',
        description: 'Reach level 9',
        emoji: '⚔️',
        progress: s.level,
        goal: 9,
      ),
    ];
  }
}

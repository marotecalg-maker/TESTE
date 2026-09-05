import 'anime.dart';
import 'watch_status.dart';

/// An anime the user has saved to their personal library, plus their
/// tracking data (status, episode progress, personal rating).
///
/// Stored in Hive as a plain JSON map so no code generation is required.
class TrackedAnime {
  final int id;
  final String title;
  final String imageUrl;
  final int? totalEpisodes;
  final double? communityScore;
  final List<String> genres;
  final String type;

  final WatchStatus status;
  final int progress; // episodes watched
  final double userRating; // 0..10, 0 = unrated
  final bool favorite;
  final int addedAt; // epoch ms
  final int updatedAt; // epoch ms

  const TrackedAnime({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.status,
    this.totalEpisodes,
    this.communityScore,
    this.genres = const [],
    this.type = 'TV',
    this.progress = 0,
    this.userRating = 0,
    this.favorite = false,
    required this.addedAt,
    required this.updatedAt,
  });

  bool get isFinished =>
      totalEpisodes != null && totalEpisodes! > 0 && progress >= totalEpisodes!;

  double get progressFraction {
    if (totalEpisodes == null || totalEpisodes == 0) {
      return status == WatchStatus.completed ? 1 : 0;
    }
    return (progress / totalEpisodes!).clamp(0, 1);
  }

  /// Episodes counted as "watched" for stats — a completed show with an
  /// unknown/zero progress still counts its full length.
  int get watchedEpisodes {
    if (status == WatchStatus.completed && totalEpisodes != null) {
      return totalEpisodes!;
    }
    return progress;
  }

  factory TrackedAnime.fromAnime(Anime a, WatchStatus status) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return TrackedAnime(
      id: a.id,
      title: a.displayTitle,
      imageUrl: a.imageUrl,
      totalEpisodes: a.episodes,
      communityScore: a.score,
      genres: a.genres,
      type: a.type,
      status: status,
      progress: status == WatchStatus.completed ? (a.episodes ?? 0) : 0,
      addedAt: now,
      updatedAt: now,
    );
  }

  TrackedAnime copyWith({
    WatchStatus? status,
    int? progress,
    double? userRating,
    bool? favorite,
    int? totalEpisodes,
  }) {
    return TrackedAnime(
      id: id,
      title: title,
      imageUrl: imageUrl,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      communityScore: communityScore,
      genres: genres,
      type: type,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      userRating: userRating ?? this.userRating,
      favorite: favorite ?? this.favorite,
      addedAt: addedAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'totalEpisodes': totalEpisodes,
        'communityScore': communityScore,
        'genres': genres,
        'type': type,
        'status': status.storageKey,
        'progress': progress,
        'userRating': userRating,
        'favorite': favorite,
        'addedAt': addedAt,
        'updatedAt': updatedAt,
      };

  factory TrackedAnime.fromJson(Map<String, dynamic> json) {
    return TrackedAnime(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      imageUrl: (json['imageUrl'] ?? '') as String,
      totalEpisodes: json['totalEpisodes'] as int?,
      communityScore: (json['communityScore'] as num?)?.toDouble(),
      genres: (json['genres'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      type: (json['type'] ?? 'TV') as String,
      status: WatchStatus.fromKey(json['status'] as String?),
      progress: (json['progress'] ?? 0) as int,
      userRating: ((json['userRating'] ?? 0) as num).toDouble(),
      favorite: (json['favorite'] ?? false) as bool,
      addedAt: (json['addedAt'] ?? 0) as int,
      updatedAt: (json['updatedAt'] ?? 0) as int,
    );
  }
}

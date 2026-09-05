/// A single anime entry as returned by the Jikan (MyAnimeList) API.
/// Parsing is defensive: the public API frequently returns nulls.
class Anime {
  final int id;
  final String title;
  final String? titleEnglish;
  final String? titleJapanese;
  final String imageUrl;
  final String? trailerId; // youtube id
  final String? synopsis;
  final String type; // TV, Movie, OVA...
  final int? episodes;
  final String? status; // Airing, Finished Airing...
  final double? score;
  final int? rank;
  final int? popularity;
  final int? members;
  final int? year;
  final String? season;
  final String? rating; // age rating
  final List<String> genres;
  final List<String> studios;

  const Anime({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.titleEnglish,
    this.titleJapanese,
    this.trailerId,
    this.synopsis,
    this.type = 'TV',
    this.episodes,
    this.status,
    this.score,
    this.rank,
    this.popularity,
    this.members,
    this.year,
    this.season,
    this.rating,
    this.genres = const [],
    this.studios = const [],
  });

  /// A clean, user-facing display title (prefers English when available).
  String get displayTitle =>
      (titleEnglish != null && titleEnglish!.trim().isNotEmpty)
          ? titleEnglish!
          : title;

  String get episodesLabel => episodes == null ? '?' : '$episodes';

  String get yearSeasonLabel {
    if (season != null && year != null) {
      final s = season![0].toUpperCase() + season!.substring(1);
      return '$s $year';
    }
    if (year != null) return '$year';
    return type;
  }

  factory Anime.fromJson(Map<String, dynamic> json) {
    // Cover image: prefer the largest jpg, fall back gracefully.
    final images = json['images'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    final image = (jpg?['large_image_url'] ??
            jpg?['image_url'] ??
            '') as String;

    final trailer = json['trailer'] as Map<String, dynamic>?;

    List<String> namesOf(String key) {
      final list = json[key] as List<dynamic>?;
      if (list == null) return const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => (e['name'] ?? '').toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return Anime(
      id: (json['mal_id'] ?? 0) as int,
      title: (json['title'] ?? 'Unknown') as String,
      titleEnglish: json['title_english'] as String?,
      titleJapanese: json['title_japanese'] as String?,
      imageUrl: image,
      trailerId: trailer?['youtube_id'] as String?,
      synopsis: json['synopsis'] as String?,
      type: (json['type'] ?? 'TV') as String? ?? 'TV',
      episodes: json['episodes'] as int?,
      status: json['status'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      rank: json['rank'] as int?,
      popularity: json['popularity'] as int?,
      members: json['members'] as int?,
      year: json['year'] as int?,
      season: json['season'] as String?,
      rating: json['rating'] as String?,
      genres: namesOf('genres'),
      studios: namesOf('studios'),
    );
  }
}

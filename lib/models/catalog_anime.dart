import 'package:json_annotation/json_annotation.dart';

part 'catalog_anime.g.dart';

@JsonSerializable()
class Anime {
  final String? title;
  final String? url;
  @JsonKey(name: 'imageUrl')
  final String? imageUrl;
  final String? status;
  final String? type;
  final String? description;
  @JsonKey(name: 'createdAt')
  final String? createdAt;
  @JsonKey(name: 'updatedAt')
  final String? updatedAt;
  final List<String>? genres;
  final List<Episode>? episodes;

  Anime({
    this.title,
    this.url,
    this.imageUrl,
    this.status,
    this.type,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.genres,
    this.episodes,
  });

  factory Anime.fromJson(Map<String, dynamic> json) => _$AnimeFromJson(json);
  Map<String, dynamic> toJson() => _$AnimeToJson(this);
}

@JsonSerializable()
class Episode {
  @JsonKey(fromJson: _numberFromJson)
  final String? number;
  final String? title;
  final String? url;
  final List<Server>? servers;
  @JsonKey(name: 'isWatched')
  final bool isWatched;

  Episode({
    this.number,
    this.title,
    this.url,
    this.servers,
    this.isWatched = false,
  });

  static String? _numberFromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toString();
    if (value is String) return value;
    return value.toString();
  }

  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);
  Map<String, dynamic> toJson() => _$EpisodeToJson(this);
}

@JsonSerializable()
class Server {
  final String? name;
  final String? url;
  final String? quality;
  final String? resolution;
  @JsonKey(name: 'size_mb')
  final double? sizeMb;
  final String? source;
  @JsonKey(name: 'extracted_from')
  final String? extractedFrom;
  @JsonKey(name: 'uploaded_at')
  final String? uploadedAt;
  @JsonKey(name: 'checked_at')
  final String? checkedAt;

  Server({
    this.name,
    this.url,
    this.quality,
    this.resolution,
    this.sizeMb,
    this.source,
    this.extractedFrom,
    this.uploadedAt,
    this.checkedAt,
  });

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);
  Map<String, dynamic> toJson() => _$ServerToJson(this);
}

@JsonSerializable()
class AnimeResponse {
  final bool success;
  final List<Anime> data;

  AnimeResponse({
    required this.success,
    required this.data,
  });

  factory AnimeResponse.fromJson(Map<String, dynamic> json) => _$AnimeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AnimeResponseToJson(this);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_anime.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Anime _$AnimeFromJson(Map<String, dynamic> json) => Anime(
  title: json['title'] as String?,
  url: json['url'] as String?,
  imageUrl: json['imageUrl'] as String?,
  status: json['status'] as String?,
  type: json['type'] as String?,
  description: json['description'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  genres: (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
  episodes: (json['episodes'] as List<dynamic>?)
      ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AnimeToJson(Anime instance) => <String, dynamic>{
  'title': instance.title,
  'url': instance.url,
  'imageUrl': instance.imageUrl,
  'status': instance.status,
  'type': instance.type,
  'description': instance.description,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'genres': instance.genres,
  'episodes': instance.episodes,
};

Episode _$EpisodeFromJson(Map<String, dynamic> json) => Episode(
  number: Episode._numberFromJson(json['number']),
  title: json['title'] as String?,
  url: json['url'] as String?,
  servers: (json['servers'] as List<dynamic>?)
      ?.map((e) => Server.fromJson(e as Map<String, dynamic>))
      .toList(),
  isWatched: json['isWatched'] as bool? ?? false,
);

Map<String, dynamic> _$EpisodeToJson(Episode instance) => <String, dynamic>{
  'number': instance.number,
  'title': instance.title,
  'url': instance.url,
  'servers': instance.servers,
  'isWatched': instance.isWatched,
};

Server _$ServerFromJson(Map<String, dynamic> json) => Server(
  name: json['name'] as String?,
  url: json['url'] as String?,
  quality: json['quality'] as String?,
  resolution: json['resolution'] as String?,
  sizeMb: (json['size_mb'] as num?)?.toDouble(),
  source: json['source'] as String?,
  extractedFrom: json['extracted_from'] as String?,
  uploadedAt: json['uploaded_at'] as String?,
  checkedAt: json['checked_at'] as String?,
);

Map<String, dynamic> _$ServerToJson(Server instance) => <String, dynamic>{
  'name': instance.name,
  'url': instance.url,
  'quality': instance.quality,
  'resolution': instance.resolution,
  'size_mb': instance.sizeMb,
  'source': instance.source,
  'extracted_from': instance.extractedFrom,
  'uploaded_at': instance.uploadedAt,
  'checked_at': instance.checkedAt,
};

AnimeResponse _$AnimeResponseFromJson(Map<String, dynamic> json) =>
    AnimeResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => Anime.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnimeResponseToJson(AnimeResponse instance) =>
    <String, dynamic>{'success': instance.success, 'data': instance.data};

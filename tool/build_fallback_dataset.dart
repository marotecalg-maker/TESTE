// One-off script: combine cached Jikan API responses into a bundled
// offline fallback dataset so Discover/Explore never show a blank error
// screen if the network or the Jikan API is unavailable.
//
// Run with: dart run tool/build_fallback_dataset.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final srcDir = Directory(r'E:\flutter-temp\rosome_fallback');
  final out = <Map<String, dynamic>>[];
  final seen = <int>{};

  void addItem(Map<String, dynamic> item) {
    final id = item['mal_id'] as int?;
    final images = item['images'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    final image = jpg?['large_image_url'] ?? jpg?['image_url'];
    if (id == null || image == null || seen.contains(id)) return;
    seen.add(id);
    out.add({
      'mal_id': id,
      'title': item['title'],
      'title_english': item['title_english'],
      'images': images,
      'trailer': item['trailer'],
      'synopsis': item['synopsis'],
      'type': item['type'],
      'episodes': item['episodes'],
      'status': item['status'],
      'score': item['score'],
      'rank': item['rank'],
      'popularity': item['popularity'],
      'members': item['members'],
      'year': item['year'],
      'season': item['season'],
      'rating': item['rating'],
      'genres': item['genres'],
      'studios': item['studios'],
    });
  }

  for (final f in srcDir.listSync().whereType<File>()) {
    final body = json.decode(f.readAsStringSync());
    if (body is! Map<String, dynamic>) continue;
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      addItem(data);
    } else if (data is List) {
      for (final e in data) {
        if (e is Map<String, dynamic>) addItem(e);
      }
    }
  }

  final outFile = File('assets/fallback_anime.json');
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
  stderr.writeln('Wrote ${out.length} entries to ${outFile.path}');
}

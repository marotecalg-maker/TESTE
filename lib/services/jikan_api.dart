import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/anime.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Thin client over the free Jikan v4 API (unofficial MyAnimeList).
/// No API key required. We keep requests SFW and throttle them so we stay
/// under Jikan's ~3 req/sec limit.
class JikanApi {
  JikanApi._();
  static final JikanApi instance = JikanApi._();

  static const String _base = 'https://api.jikan.moe/v4';
  final http.Client _client = http.Client();

  // Simple serial throttle: never fire two requests closer than [_minGap].
  static const Duration _minGap = Duration(milliseconds: 420);
  DateTime _lastCall = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _lock = Future.value();

  Future<Map<String, dynamic>> _get(String path) {
    // Chain onto the previous call so requests run one-at-a-time, spaced out.
    final completer = Completer<Map<String, dynamic>>();
    _lock = _lock.then((_) async {
      // Transient failures (timeouts, 429s, 5xx, dropped connections) are
      // common on Jikan's free/shared API — retry a few times with backoff
      // before giving up, so a single blip doesn't blank the whole screen.
      const maxAttempts = 4;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        final since = DateTime.now().difference(_lastCall);
        if (since < _minGap) {
          await Future.delayed(_minGap - since);
        }
        try {
          final res = await _client
              .get(Uri.parse('$_base$path'))
              .timeout(const Duration(seconds: 20));
          _lastCall = DateTime.now();
          if (res.statusCode == 429 || res.statusCode >= 500) {
            throw ApiException(res.statusCode == 429
                ? 'Rate limited — try again in a moment.'
                : 'Server error (${res.statusCode}).');
          }
          if (res.statusCode != 200) {
            completer.completeError(
                ApiException('Server error (${res.statusCode}).'));
            return;
          }
          completer.complete(
            json.decode(res.body) as Map<String, dynamic>,
          );
          return;
        } on TimeoutException {
          if (attempt == maxAttempts) {
            completer.completeError(ApiException('Request timed out.'));
            return;
          }
        } on ApiException catch (e) {
          if (attempt == maxAttempts) {
            completer.completeError(e);
            return;
          }
        } catch (_) {
          if (attempt == maxAttempts) {
            completer.completeError(ApiException('Check your connection.'));
            return;
          }
        }
        // Exponential backoff before the next attempt: ~0.6s, 1.2s, 2.4s.
        await Future.delayed(Duration(milliseconds: 600 * (1 << (attempt - 1))));
      }
    });
    return completer.future;
  }

  List<Anime> _parseList(Map<String, dynamic> body) {
    final data = body['data'] as List<dynamic>? ?? const [];
    return _dedupe(data);
  }

  List<Anime> _dedupe(List<dynamic> data) {
    final seen = <int>{};
    final out = <Anime>[];
    for (final e in data.whereType<Map<String, dynamic>>()) {
      final a = Anime.fromJson(e);
      if (a.imageUrl.isEmpty || seen.contains(a.id)) continue;
      seen.add(a.id);
      out.add(a);
    }
    return out;
  }

  List<Anime>? _bundledFallback;

  /// A small set of well-known titles bundled with the app, used when the
  /// network or Jikan itself is unreachable so Discover/Explore always have
  /// something to show instead of a dead-end error screen.
  Future<List<Anime>> fallback() async {
    if (_bundledFallback != null) return _bundledFallback!;
    final raw = await rootBundle.loadString('assets/fallback_anime.json');
    final list = _bundledFallback = _dedupe(json.decode(raw) as List<dynamic>);
    return list;
  }

  /// Currently trending — Jikan's most-popular airing titles.
  Future<List<Anime>> trending({int page = 1}) =>
      _get('/top/anime?filter=airing&sfw=true&page=$page').then(_parseList);

  /// All-time top rated.
  Future<List<Anime>> topRated({int page = 1}) =>
      _get('/top/anime?filter=bypopularity&sfw=true&page=$page')
          .then(_parseList);

  /// Highest scored.
  Future<List<Anime>> topScored({int page = 1}) =>
      _get('/top/anime?sfw=true&page=$page').then(_parseList);

  /// This season's new releases.
  Future<List<Anime>> seasonNow({int page = 1}) =>
      _get('/seasons/now?sfw=true&page=$page').then(_parseList);

  Future<List<Anime>> search(String query, {int page = 1}) {
    final q = Uri.encodeQueryComponent(query.trim());
    return _get('/anime?q=$q&sfw=true&order_by=popularity&page=$page')
        .then(_parseList);
  }

  Future<List<Anime>> byGenre(int genreId, {int page = 1}) =>
      _get('/anime?genres=$genreId&sfw=true&order_by=popularity&page=$page')
          .then(_parseList);

  Future<Anime> detail(int id) =>
      _get('/anime/$id/full').then((b) => Anime.fromJson(b['data'] as Map<String, dynamic>));

  /// Recommendations related to a given anime (used on the detail screen).
  Future<List<Anime>> recommendations(int id) async {
    final body = await _get('/anime/$id/recommendations');
    final data = body['data'] as List<dynamic>? ?? const [];
    final out = <Anime>[];
    final seen = <int>{};
    for (final e in data.whereType<Map<String, dynamic>>()) {
      final entry = e['entry'] as Map<String, dynamic>?;
      if (entry == null) continue;
      final a = Anime.fromJson(entry);
      if (a.imageUrl.isEmpty || seen.contains(a.id)) continue;
      seen.add(a.id);
      out.add(a);
      if (out.length >= 12) break;
    }
    return out;
  }
}

/// A curated set of genre filters shown on the Explore screen.
/// (ids are stable MyAnimeList genre ids.)
class GenreFilter {
  final int id;
  final String name;
  const GenreFilter(this.id, this.name);

  static const List<GenreFilter> all = [
    GenreFilter(1, 'Action'),
    GenreFilter(2, 'Adventure'),
    GenreFilter(4, 'Comedy'),
    GenreFilter(8, 'Drama'),
    GenreFilter(10, 'Fantasy'),
    GenreFilter(7, 'Mystery'),
    GenreFilter(22, 'Romance'),
    GenreFilter(24, 'Sci-Fi'),
    GenreFilter(36, 'Slice of Life'),
    GenreFilter(30, 'Sports'),
    GenreFilter(37, 'Supernatural'),
    GenreFilter(41, 'Suspense'),
  ];
}

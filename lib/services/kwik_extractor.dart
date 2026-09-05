import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Why an extraction attempt did not produce an m3u8.
///
/// These are deliberately distinct: on some networks the embed path is behind
/// a Cloudflare rule ([blocked]) while the host answers normally elsewhere,
/// and that needs a different message — and a different remedy — than a dead
/// token ([notFound]) or a page whose shape changed ([noPackerBlock], [noM3u8]).
enum KwikError {
  /// 403 / Cloudflare interstitial. This network is not allowed to fetch /e/.
  blocked,

  /// The request did not complete within the timeout.
  timeout,

  /// DNS failure, connection refused, TLS failure — the host was unreachable.
  network,

  /// 404 or similar: the token is gone.
  notFound,

  /// Any other non-200 status.
  httpError,

  /// Page fetched, but it contained no eval(function(p,a,c,k,e,d)) block.
  noPackerBlock,

  /// A packer block unpacked, but no .m3u8 URL was found in the result.
  noM3u8,
}

/// Outcome of a kwik embed resolution.
class KwikResult {
  /// The playlist URL. Non-null exactly when the attempt succeeded.
  final String? m3u8Url;

  /// Headers a player must send when fetching [m3u8Url] and its segments.
  /// Null on failure.
  final Map<String, String>? streamHeaders;

  final KwikError? error;

  /// HTTP status that produced [error], when there was one.
  final int? statusCode;

  const KwikResult._({
    this.m3u8Url,
    this.streamHeaders,
    this.error,
    this.statusCode,
  });

  const KwikResult.success(String url, Map<String, String> headers)
      : this._(m3u8Url: url, streamHeaders: headers);

  const KwikResult.failure(KwikError error, {int? statusCode})
      : this._(error: error, statusCode: statusCode);

  bool get isSuccess => m3u8Url != null;

  /// Message suitable for the player UI.
  String get message {
    switch (error) {
      case KwikError.blocked:
        return 'The video host is refusing connections from your network. '
            'A VPN set to another country is the usual workaround.';
      case KwikError.timeout:
        return 'The video host did not respond. Check your connection.';
      case KwikError.network:
        return 'Could not reach the video host.';
      case KwikError.notFound:
        return 'This episode link has expired.';
      case KwikError.httpError:
        return 'The video host returned an error'
            '${statusCode != null ? ' ($statusCode)' : ''}.';
      case KwikError.noPackerBlock:
      case KwikError.noM3u8:
        return 'Could not read the video stream from this source. '
            'Try another server.';
      case null:
        return '';
    }
  }
}

/// Resolves kwik embed pages to their m3u8 playlist.
///
/// Known limitation: kwik sits behind a Cloudflare rule that serves /e/ only
/// over **HTTP/2**, and only with the embed host as the `Referer`. Measured
/// against the same URL:
///
/// | request                          | result |
/// |----------------------------------|--------|
/// | HTTP/2  + Referer + browser UA   | 200    |
/// | HTTP/1.1 + identical headers     | 403    |
/// | HTTP/2  without Referer          | 403    |
///
/// `dart:io`'s HttpClient — and therefore `package:http` — speaks HTTP/1.1
/// only, so [resolve] returns [KwikError.blocked] on most networks however the
/// headers are set. That is not a bug to fix here: the caller should fall back
/// to the WebView, which is a real browser and negotiates HTTP/2. The direct
/// path is kept because it is faster where it does work and because it cleanly
/// distinguishes a dead token from a block.
class KwikExtractor {
  static const String _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// Headers for the *m3u8 and segment* requests. The embed host is both the
  /// referrer and the origin for those, so they track the host in use.
  static Map<String, String> streamHeadersFor(String embedHost) => {
        'Referer': 'https://$embedHost/',
        'Origin': 'https://$embedHost',
        'User-Agent': _userAgent,
      };

  /// Retained for callers that still read a fixed map.
  static const Map<String, String> streamHeaders = {
    'Referer': 'https://kwik.cx/',
    'Origin': 'https://kwik.cx',
    'User-Agent': _userAgent,
  };

  /// Headers for fetching the *embed page* itself.
  ///
  /// The embed host is its own referrer. That is what the host accepts; an
  /// animepahe referrer with an animepahe Origin turns the request into a
  /// cross-origin one and is refused.
  static Map<String, String> _embedHeaders(String host, String? refererUrl) => {
        'Referer': refererUrl ?? 'https://$host/',
        'User-Agent': _userAgent,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
      };

  /// Resolves a kwik embed URL to its m3u8 playlist.
  ///
  /// [refererUrl] overrides the Referer sent with the embed request. Leave it
  /// unset — the default (the embed host itself) is what the host accepts.
  static Future<KwikResult> resolve(
    String kwikUrl, {
    String? refererUrl,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final host = Uri.tryParse(kwikUrl)?.host ?? 'kwik.cx';

    http.Response response;
    try {
      response = await http
          .get(Uri.parse(kwikUrl), headers: _embedHeaders(host, refererUrl))
          .timeout(timeout);
    } on TimeoutException {
      debugPrint('KwikExtractor: timeout fetching $kwikUrl');
      return const KwikResult.failure(KwikError.timeout);
    } catch (e) {
      debugPrint('KwikExtractor: network failure for $kwikUrl -> $e');
      return const KwikResult.failure(KwikError.network);
    }

    debugPrint(
      'KwikExtractor: $kwikUrl -> ${response.statusCode}, '
      '${response.body.length} bytes',
    );

    if (response.statusCode != 200) {
      return KwikResult.failure(
        _classifyStatus(response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final html = response.body;

    // A Cloudflare block can also come back as a 200 challenge page.
    if (_looksBlocked(html)) {
      return const KwikResult.failure(KwikError.blocked, statusCode: 200);
    }

    final blocks = _packerPattern.allMatches(html).toList();
    debugPrint('KwikExtractor: ${blocks.length} packer block(s)');
    if (blocks.isEmpty) {
      return const KwikResult.failure(KwikError.noPackerBlock);
    }

    for (final block in blocks) {
      final k = block.group(4)!.split('|');
      final unpacked = _unpackBlock(
        block.group(1)!,
        int.parse(block.group(2)!),
        k.length,
        k,
      );
      if (unpacked == null) continue;

      final m3u8Match = _m3u8Pattern.firstMatch(unpacked);
      if (m3u8Match != null) {
        debugPrint('KwikExtractor: m3u8 -> ${m3u8Match.group(0)}');
        return KwikResult.success(m3u8Match.group(0)!, streamHeadersFor(host));
      }
    }

    return const KwikResult.failure(KwikError.noM3u8);
  }

  /// Backwards-compatible wrapper: the m3u8 URL, or null on any failure.
  ///
  /// Prefer [resolve] — this form cannot tell a blocked network from a dead
  /// token, so the UI can only ever show one generic message.
  static Future<String?> extractM3u8(String kwikUrl, {String? refererUrl}) async {
    final result = await resolve(kwikUrl, refererUrl: refererUrl);
    return result.m3u8Url;
  }

  static KwikError _classifyStatus(int status) {
    if (status == 403 || status == 503) return KwikError.blocked;
    if (status == 404 || status == 410) return KwikError.notFound;
    return KwikError.httpError;
  }

  static bool _looksBlocked(String html) {
    // Cloudflare serves these under both 403 and 200 depending on the rule.
    const markers = [
      'you have been blocked',
      'cf-error-details',
      'attention required! | cloudflare',
      'just a moment...',
    ];
    final lower = html.toLowerCase();
    return markers.any(lower.contains);
  }

  static final RegExp _packerPattern = RegExp(
    r"eval\(function\(p,a,c,k,e,d\)\{.*?\}\('(.*?)',(\d+),(\d+),'(.*?)'\.split\('\|'\),\d+,\{\}\)\)",
    dotAll: true,
  );

  static final RegExp _m3u8Pattern = RegExp(r'''https?://\S+?\.m3u8[^\s"'\\]*''');

  static String? _unpackBlock(String p, int a, int c, List<String> k) {
    String encode(int n) {
      var result = '';
      if (n >= a) result = encode(n ~/ a);
      final r = n % a;
      if (r > 35) return result + String.fromCharCode(r + 29);
      if (r >= 10) return result + String.fromCharCode(r + 87);
      return result + r.toString();
    }

    final d = <String, String>{};
    for (var i = 0; i < c; i++) {
      final key = encode(i);
      d[key] = (i < k.length && k[i].isNotEmpty) ? k[i] : key;
    }

    return p.replaceAllMapped(
      RegExp(r'\w+'),
      (m) => d[m.group(0)!] ?? m.group(0)!,
    );
  }
}

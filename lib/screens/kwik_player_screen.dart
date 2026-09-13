import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/catalog_anime.dart';
import '../services/kwik_extractor.dart';
import '../services/ad_gate.dart';

/// A self-contained player for kwik embed links.
///
/// Give it the [Server] list from an [Episode] and it handles quality
/// filtering, server selection and playback. It has no dependency on ads,
/// billing or any particular design system — it styles itself from
/// `Theme.of(context)` — so it drops into any app unchanged.
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => KwikPlayerScreen(
///     servers: episode.servers,
///     title: '${anime.title} - ${episode.number}',
///   ),
/// ));
/// ```
class KwikPlayerScreen extends StatefulWidget {
  const KwikPlayerScreen({
    super.key,
    required this.servers,
    this.title,
    this.onBeforePlay,
    this.autoPlayFirst = true,
  });

  /// Servers for one episode. Entries without a URL are ignored.
  final List<Server>? servers;

  final String? title;

  /// Awaited before each playback attempt. This is the hook for anything the
  /// host app wants to run first — a rewarded ad, a subscription check, an
  /// analytics event. Throwing or returning normally both proceed to play.
  final Future<void> Function()? onBeforePlay;

  /// Start the highest-quality server automatically on open.
  final bool autoPlayFirst;

  @override
  State<KwikPlayerScreen> createState() => _KwikPlayerScreenState();
}

class _KwikPlayerScreenState extends State<KwikPlayerScreen> {
  WebViewController? _controller;
  String? _selectedQuality;
  Server? _activeServer;
  bool _isLoading = false;
  bool _showPlayer = false;
  String? _error;

  List<Server> get _servers =>
      (widget.servers ?? []).where((s) => (s.url ?? '').isNotEmpty).toList();

  /// Distinct qualities, highest first. Falls back to source order for labels
  /// that carry no parsable number.
  List<String> get _qualities {
    final seen = <String>{};
    for (final s in _servers) {
      final q = s.quality?.trim();
      if (q != null && q.isNotEmpty) seen.add(q);
    }
    final list = seen.toList();
    list.sort((a, b) => (_qualityRank(b)).compareTo(_qualityRank(a)));
    return list;
  }

  static int _qualityRank(String q) =>
      int.tryParse(RegExp(r'\d+').firstMatch(q)?.group(0) ?? '') ?? 0;

  List<Server> get _visibleServers => _selectedQuality == null
      ? _servers
      : _servers.where((s) => s.quality?.trim() == _selectedQuality).toList();

  @override
  void initState() {
    super.initState();
    final qualities = _qualities;
    if (qualities.isNotEmpty) _selectedQuality = qualities.first;
    if (widget.autoPlayFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final first = _visibleServers.isNotEmpty
            ? _visibleServers.first
            : (_servers.isNotEmpty ? _servers.first : null);
        if (first != null) _play(first);
      });
    }
  }

  Future<void> _play(Server server) async {
    final url = server.url;
    if (url == null || url.isEmpty) return;

    if (kIsWeb) {
      // kwik playback needs a native WebView + native HTTP (no CORS). A web
      // build has neither — the fetch is CORS-blocked and webview_flutter has
      // no web implementation — so surface a clear message instead of failing
      // with an obscure "could not reach the host".
      setState(() {
        _activeServer = null;
        _isLoading = false;
        _showPlayer = false;
        _error = AppLocalizations.of(context).t('web_playback_unsupported');
      });
      return;
    }

    setState(() {
      _activeServer = server;
      _isLoading = true;
      _showPlayer = false;
      _error = null;
    });

    if (widget.onBeforePlay != null) {
      try {
        await widget.onBeforePlay!();
      } catch (_) {
        // A failing pre-play hook must never block playback.
      }
    }
    if (!mounted) return;

    final result = await KwikExtractor.resolve(url);
    if (!mounted) return;

    if (result.isSuccess) {
      _attachHlsPlayer(result.m3u8Url!, Uri.tryParse(url)?.host ?? 'kwik.cx');
      return;
    }

    // Cloudflare serves the embed path over HTTP/2 only, and dart:io's
    // HttpClient is HTTP/1.1-only, so the direct fetch is refused on most
    // networks. The WebView is a real browser: hand the page to it with the
    // Referer attached and let the host's own player run.
    if (result.error == KwikError.blocked ||
        result.error == KwikError.network ||
        result.error == KwikError.timeout) {
      _attachEmbedPage(url, fallbackMessage: result.message);
      return;
    }

    setState(() {
      _isLoading = false;
      _error = result.message;
    });
  }

  /// Plays an extracted playlist through hls.js.
  ///
  /// `baseUrl` is what makes this work: the WebView then sends the embed host
  /// as the Referer for the playlist, every segment and every key request,
  /// which is what the CDN checks.
  void _attachHlsPlayer(String m3u8Url, String embedHost) {
    final html = '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
  video { width: 100%; height: 100%; object-fit: contain; }
</style>
</head>
<body>
<video id="v" controls autoplay playsinline webkit-playsinline></video>
<script src="https://cdn.jsdelivr.net/npm/hls.js@1.5.20/dist/hls.min.js"></script>
<script>
(function () {
  var src = "$m3u8Url";
  var video = document.getElementById("v");
  if (window.Hls && Hls.isSupported()) {
    var hls = new Hls({ enableWorker: false });
    hls.loadSource(src);
    hls.attachMedia(video);
    hls.on(Hls.Events.MANIFEST_PARSED, function () { video.play(); });
  } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
    // Safari/WKWebView play HLS natively.
    video.src = src;
    video.play();
  }
})();
</script>
</body>
</html>''';

    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..enableZoom(false)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) => _markReady(),
          ),
        )
        ..loadHtmlString(html, baseUrl: 'https://$embedHost/');
      setState(() => _showPlayer = true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Could not start the player: $e';
      });
    }
  }

  /// Loads the embed page itself, with the Referer the host requires.
  void _attachEmbedPage(String embedUrl, {required String fallbackMessage}) {
    final host = Uri.tryParse(embedUrl)?.host ?? 'kwik.cx';
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..enableZoom(false)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) => _markReady(),
            onWebResourceError: (_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _error = fallbackMessage;
                });
              }
            },
          ),
        )
        ..loadRequest(
          Uri.parse(embedUrl),
          headers: {
            'Referer': 'https://$host/',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        );
      setState(() => _showPlayer = true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = fallbackMessage;
      });
    }
  }

  void _markReady() {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _showPlayer = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title ?? 'Player',
          style: const TextStyle(color: Colors.white, fontSize: 17),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // On short/wide viewports (web preview, phone landscape) a width-based
          // 16:9 stage is taller than the screen and overflows the column, so
          // cap its height and let the server list keep the remainder.
          final videoHeight = math.min(
            constraints.maxWidth * 9 / 16,
            constraints.maxHeight * 0.72,
          );
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: videoHeight,
                child: _buildStage(),
              ),
              Expanded(
                child: Container(
                  color: theme.scaffoldBackgroundColor,
                  child: _servers.isEmpty
                      ? const Center(
                          child: Text('No servers for this episode.'))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (_qualities.length > 1) ...[
                              Text('Quality',
                                  style: theme.textTheme.titleSmall),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  for (final q in _qualities)
                                    ChoiceChip(
                                      label: Text(q),
                                      selected: _selectedQuality == q,
                                      onSelected: (_) {
                                        AdGate.onTap();
                                        setState(
                                            () => _selectedQuality = q);
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                            Text('Servers',
                                style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            for (final s in _visibleServers)
                              _serverTile(s, theme),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStage() {
    if (_error != null) {
      return Container(
        color: Colors.black,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (_activeServer != null)
              TextButton.icon(
                onPressed: () => AdGate.showRewardedThen(() {
                  if (mounted && _activeServer != null) _play(_activeServer!);
                }),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      );
    }

    if (_isLoading || _controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Text(
                  'Pick a server to start',
                  style: TextStyle(color: Colors.white54),
                ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: !_showPlayer, child: WebViewWidget(controller: _controller!)),
        if (!_showPlayer)
          const ColoredBox(
            color: Colors.black,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );
  }

  Widget _serverTile(Server s, ThemeData theme) {
    final active = identical(s, _activeServer);
    final bits = <String>[
      if ((s.quality ?? '').isNotEmpty) s.quality!,
      if (s.sizeMb != null) _size(s.sizeMb!),
      if ((s.source ?? '').isNotEmpty) s.source!,
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: active ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: active ? theme.colorScheme.primary : theme.dividerColor,
        ),
      ),
      child: ListTile(
        leading: Icon(
          active ? Icons.play_circle_fill : Icons.dns_outlined,
          color: active ? theme.colorScheme.primary : null,
        ),
        title: Text(s.name ?? 'Server', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: bits.isEmpty ? null : Text(bits.join('  •  ')),
        // Each stream starts behind a rewarded ad.
        onTap: () => AdGate.showRewardedThen(() {
          if (mounted) _play(s);
        }),
      ),
    );
  }

  static String _size(double mb) =>
      mb < 1024 ? '${mb.toStringAsFixed(0)}MB' : '${(mb / 1024).toStringAsFixed(1)}GB';
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/catalog_anime.dart';
import '../providers/anime_provider.dart';
import '../screens/kwik_player_screen.dart';
import '../services/ad_gate.dart';
import '../theme/app_theme.dart';

/// Episodes that actually have at least one playable server (a real link).
List<Episode> playableEpisodes(Anime match) => (match.episodes ?? [])
    .where((e) => (e.servers ?? []).any((s) => (s.url ?? '').isNotEmpty))
    .toList();

/// Opens the [KwikPlayerScreen] for one catalog [episode] and records it as
/// watched. Shared by the inline list, the full-list screen and the "Watch
/// now" button so playback behaves identically everywhere.
///
/// Playback sits behind a rewarded ad when one is loaded; the player opens
/// once the ad closes (or right away when there is no ad).
void openEpisodePlayer(
  BuildContext context, {
  required Anime match,
  required String heroTitle,
  required Episode episode,
}) {
  final l = AppLocalizations.of(context);
  final number = episode.number ?? '';
  final title = '$heroTitle • ${l.t('episode')} $number';
  // Resolved up front: the continuation may run after the ad, when this
  // context is no longer safe to read.
  final provider = context.read<AnimeProvider>();
  final navigator = Navigator.of(context);
  AdGate.showRewardedThen(() {
    provider.markEpisodeAsWatched(match.title ?? heroTitle, number);
    navigator.push(
      MaterialPageRoute(
        builder: (_) => KwikPlayerScreen(
          servers: episode.servers,
          title: title,
        ),
      ),
    );
  });
}

/// An inline, always-visible list of an anime's playable episodes — each row
/// shows its number, title and available qualities, and taps straight into the
/// player. Lives on the detail screen so the episodes (and their links) are
/// visible without opening a sheet.
///
/// Long-runners (One Piece, Naruto…) would be thousands of eager tiles, so the
/// inline list is capped at [maxInline] and the rest open in [EpisodesScreen],
/// which builds lazily.
class EpisodesSection extends StatelessWidget {
  const EpisodesSection({
    super.key,
    required this.match,
    required this.heroTitle,
    this.maxInline = 50,
  });

  final Anime match;
  final String heroTitle;
  final int maxInline;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final episodes = playableEpisodes(match);
    if (episodes.isEmpty) return const SizedBox.shrink();

    final inline = episodes.length > maxInline
        ? episodes.sublist(0, maxInline)
        : episodes;
    final hasMore = episodes.length > inline.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.playlist_play_rounded,
                color: AppColors.primaryBright),
            const SizedBox(width: 8),
            Text('${l.t('episodes')} · ${episodes.length}',
                style: AppTheme.display(18)),
          ],
        ),
        const SizedBox(height: 14),
        Consumer<AnimeProvider>(
          builder: (_, provider, __) {
            final key = match.title ?? heroTitle;
            return Column(
              children: [
                for (final ep in inline) ...[
                  EpisodeTile(
                    number: ep.number ?? '',
                    title: ep.title,
                    servers: ep.servers,
                    watched:
                        provider.isEpisodeWatched(key, ep.number ?? ''),
                    onTap: () => openEpisodePlayer(context,
                        match: match, heroTitle: heroTitle, episode: ep),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
        if (hasMore) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                AdGate.onTap();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        EpisodesScreen(match: match, heroTitle: heroTitle),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBright,
                side: BorderSide(color: AppColors.stroke),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: Text(
                  '${l.t('see_all_episodes')} (${episodes.length})'),
            ),
          ),
        ],
      ],
    );
  }
}

/// A full-screen, lazily built list of every playable episode — used when the
/// inline list is too long to render eagerly.
class EpisodesScreen extends StatelessWidget {
  const EpisodesScreen({
    super.key,
    required this.match,
    required this.heroTitle,
  });

  final Anime match;
  final String heroTitle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final episodes = playableEpisodes(match);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text('$heroTitle · ${l.t('episodes')}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Consumer<AnimeProvider>(
        builder: (_, provider, __) {
          final key = match.title ?? heroTitle;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final ep = episodes[i];
              return EpisodeTile(
                number: ep.number ?? '${i + 1}',
                title: ep.title,
                servers: ep.servers,
                watched: provider.isEpisodeWatched(key, ep.number ?? ''),
                onTap: () => openEpisodePlayer(context,
                    match: match, heroTitle: heroTitle, episode: ep),
              );
            },
          );
        },
      ),
    );
  }
}

/// One episode row: a play/watched badge, the episode number and title, and a
/// compact hint of the qualities available (so the link behind it is visible).
class EpisodeTile extends StatelessWidget {
  const EpisodeTile({
    super.key,
    required this.number,
    required this.title,
    required this.servers,
    required this.watched,
    required this.onTap,
  });

  final String number;
  final String? title;
  final List<Server>? servers;
  final bool watched;
  final VoidCallback onTap;

  /// Distinct qualities, highest first (e.g. "1080p", "720p", "480p").
  List<String> get _qualities {
    final seen = <String>{};
    for (final s in (servers ?? [])) {
      if ((s.url ?? '').isEmpty) continue;
      final q = s.quality?.trim();
      if (q != null && q.isNotEmpty) seen.add(q);
    }
    final list = seen.toList()
      ..sort((a, b) => _rank(b).compareTo(_rank(a)));
    return list;
  }

  static int _rank(String q) =>
      int.tryParse(RegExp(r'\d+').firstMatch(q)?.group(0) ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final qualities = _qualities;
    final linkCount =
        (servers ?? []).where((s) => (s.url ?? '').isNotEmpty).length;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: watched ? null : AppColors.brand,
                  color: watched ? AppColors.surfaceHigh : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  watched ? Icons.check_rounded : Icons.play_arrow_rounded,
                  color: watched ? AppColors.success : Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l.t('episode')} $number',
                      style: AppTheme.display(15, weight: FontWeight.w700),
                    ),
                    if ((title ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: AppColors.textMid, fontSize: 12.5),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.link_rounded,
                            size: 13, color: AppColors.textLow),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            qualities.isNotEmpty
                                ? qualities.join(' · ')
                                : '$linkCount',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.textLow, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textLow),
            ],
          ),
        ),
      ),
    );
  }
}

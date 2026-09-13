import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart' show contentUnlocked;
import '../l10n/app_localizations.dart';
import '../models/anime.dart';
import '../models/catalog_anime.dart' as catalog;
import '../models/watch_status.dart';
import '../providers/anime_provider.dart';
import '../services/jikan_api.dart';
import '../services/ad_gate.dart';
import '../services/library_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/network_poster.dart';
import '../widgets/poster_tile.dart';
import '../widgets/episode_list.dart';
import '../widgets/track_sheet.dart';
import '../widgets/ui_kit.dart';
import '../widgets/watch_button.dart';

class AnimeDetailScreen extends StatefulWidget {
  final Anime anime;
  const AnimeDetailScreen({super.key, required this.anime});

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  late Anime _anime;
  List<Anime> _related = const [];
  bool _synopsisExpanded = false;

  @override
  void initState() {
    super.initState();
    _anime = widget.anime;
    _load();
  }

  Future<void> _load() async {
    try {
      final full = await JikanApi.instance.detail(widget.anime.id);
      if (mounted) setState(() => _anime = full);
    } catch (_) {/* keep the partial data we already have */}
    try {
      final recs = await JikanApi.instance.recommendations(widget.anime.id);
      if (mounted) setState(() => _related = recs);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tracked = context.select<LibraryService, bool>(
        (lib) => lib.isTracked(_anime.id));
    final status = context.read<LibraryService>().get(_anime.id)?.status;

    // Bridge this Jikan entry to the bundled catalog. Non-null only once the
    // catalog has loaded and a title matches, so the Watch button appears only
    // when there are episodes to play.
    final catalog.Anime? watchMatch =
        context.watch<AnimeProvider>().findByTitles([
      _anime.title,
      if (_anime.titleEnglish != null) _anime.titleEnglish!,
      if (_anime.titleJapanese != null) _anime.titleJapanese!,
    ]);

    // Streaming (Watch Now + episodes) needs a catalog match and the remote
    // content gate to be open; otherwise the page is discover/track only.
    final canWatch = watchMatch != null && contentUnlocked;

    return Scaffold(
      bottomNavigationBar: const AdBannerSlot(slot: 'detail'),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 440,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.bg,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'poster-${_anime.id}',
                    child: NetworkPoster(url: _anime.imageUrl),
                  ),
                  const DecoratedBox(
                    decoration:
                        BoxDecoration(gradient: AppColors.posterScrim),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      child: _TitleBlock(anime: _anime),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsRow(anime: _anime),
                  const SizedBox(height: 20),
                  if (canWatch) ...[
                    WatchButton(
                      match: watchMatch,
                      heroTitle: _anime.displayTitle,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: BrandButton(
                          label: tracked
                              ? (status != null
                                  ? l.status(status)
                                  : l.t('in_library'))
                              : l.t('add_to_library'),
                          icon: tracked
                              ? Icons.edit_rounded
                              : Icons.add_rounded,
                          onTap: () {
                            AdGate.onTap();
                            showTrackSheet(context, _anime);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      _FavToggle(anime: _anime),
                    ],
                  ),
                  if (_anime.genres.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final g in _anime.genres) GenreChip(g),
                      ],
                    ),
                  ],
                  if ((_anime.synopsis ?? '').isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(l.t('synopsis'), style: AppTheme.display(18)),
                    const SizedBox(height: 8),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: _synopsisExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: _SynopsisText(_anime.synopsis!, maxLines: 5),
                      secondChild: _SynopsisText(_anime.synopsis!),
                    ),
                    GestureDetector(
                      onTap: () {
                        AdGate.onTap();
                        setState(
                            () => _synopsisExpanded = !_synopsisExpanded);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _synopsisExpanded
                              ? l.t('show_less')
                              : l.t('read_more'),
                          style: const TextStyle(
                              color: AppColors.primaryBright,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                  if (canWatch) ...[
                    const SizedBox(height: 28),
                    EpisodesSection(
                      match: watchMatch,
                      heroTitle: _anime.displayTitle,
                    ),
                  ],
                  if (_related.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(l.t('you_might_like'), style: AppTheme.display(18)),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 240,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _related.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (_, i) => PosterTile(anime: _related[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final Anime anime;
  const _TitleBlock({required this.anime});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (anime.status != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppColors.brand,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              anime.status!.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5),
            ),
          ),
        const SizedBox(height: 10),
        Text(
          anime.displayTitle,
          style: AppTheme.display(28, weight: FontWeight.w800),
        ),
        if (anime.titleJapanese != null) ...[
          const SizedBox(height: 4),
          Text(
            anime.titleJapanese!,
            style: TextStyle(color: AppColors.textMid, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Anime anime;
  const _StatsRow({required this.anime});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = <(IconData, String, String)>[
      (Icons.star_rounded, anime.score?.toStringAsFixed(1) ?? '—',
          l.t('detail_score')),
      (Icons.tv_rounded, anime.episodesLabel, l.t('detail_episodes')),
      (Icons.calendar_today_rounded, anime.yearSeasonLabel, l.t('detail_aired')),
      (Icons.people_alt_rounded, _compact(anime.members), l.t('detail_members')),
    ];
    return Row(
      children: [
        for (final it in items)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(it.$1, color: AppColors.primaryBright, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    it.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.display(14),
                  ),
                  const SizedBox(height: 2),
                  Text(it.$3,
                      style: TextStyle(
                          color: AppColors.textLow, fontSize: 10)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _compact(int? n) {
    if (n == null) return '—';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}

class _FavToggle extends StatelessWidget {
  final Anime anime;
  const _FavToggle({required this.anime});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryService>();
    final fav = lib.get(anime.id)?.favorite ?? false;
    return GestureDetector(
      onTap: () async {
        AdGate.onTap();
        if (!lib.isTracked(anime.id)) {
          // Favouriting also adds it (as planned) so it has a home.
          await lib.addFromAnime(anime, WatchStatus.planned);
        }
        await lib.toggleFavorite(anime.id);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: fav
              ? AppColors.accent.withValues(alpha: 0.16)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: fav ? AppColors.accent : Colors.transparent, width: 1.4),
        ),
        child: Icon(
          fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: fav ? AppColors.accent : AppColors.textMid,
        ),
      ),
    );
  }
}

class _SynopsisText extends StatelessWidget {
  final String text;
  final int? maxLines;
  const _SynopsisText(this.text, {this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
      style: TextStyle(
        color: AppColors.textMid,
        fontSize: 14.5,
        height: 1.6,
      ),
    );
  }
}

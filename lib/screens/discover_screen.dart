import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/anime.dart';
import '../models/watch_status.dart';
import '../services/ad_gate.dart';
import '../services/jikan_api.dart';
import '../services/library_service.dart';
import '../theme/app_theme.dart';
import '../widgets/network_poster.dart';
import '../widgets/ui_kit.dart';
import 'detail_screen.dart';

/// The signature Kioku experience: swipe through anime like a deck of cards.
/// Swipe right to save, left to skip, up to love.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final CardSwiperController _controller = CardSwiperController();
  final Set<int> _seen = {};
  List<Anime> _cards = [];
  int _page = 1;
  bool _loading = true;
  bool _error = false;
  int _deckKey = 0;

  @override
  void initState() {
    super.initState();
    // Don't re-surface anything already in the library.
    _seen.addAll(context.read<LibraryService>().all.map((e) => e.id));
    _loadBatch(initial: true);
  }

  Future<List<Anime>> _fetchNext() async {
    final out = <Anime>[];
    int guard = 0;
    while (out.length < 10 && guard < 6) {
      guard++;
      final batch = _page.isOdd
          ? await JikanApi.instance.topScored(page: _page)
          : await JikanApi.instance.trending(page: _page);
      _page++;
      for (final a in batch) {
        if (_seen.contains(a.id)) continue;
        _seen.add(a.id);
        out.add(a);
      }
      if (batch.isEmpty) break;
    }
    return out;
  }

  Future<void> _loadBatch({bool initial = false}) async {
    if (initial) setState(() => _loading = true);
    try {
      final batch = await _fetchNext();
      if (!mounted) return;
      setState(() {
        _cards = batch;
        _deckKey++;
        _loading = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Network/API unreachable — fall back to the bundled offline deck
      // rather than leaving the user on a dead-end error screen.
      try {
        final fallback = await JikanApi.instance.fallback();
        final batch = fallback.where((a) => !_seen.contains(a.id)).toList();
        _seen.addAll(batch.map((a) => a.id));
        if (!mounted) return;
        setState(() {
          _cards = batch;
          _deckKey++;
          _loading = false;
          _error = batch.isEmpty;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  void _onSwipe(int index, CardSwiperDirection dir) {
    if (index < 0 || index >= _cards.length) return;
    final anime = _cards[index];
    final lib = context.read<LibraryService>();
    switch (dir) {
      case CardSwiperDirection.right:
        lib.addFromAnime(anime, WatchStatus.planned);
        break;
      case CardSwiperDirection.top:
        lib.addFromAnime(anime, WatchStatus.planned).then((_) {
          if (!(lib.get(anime.id)?.favorite ?? false)) {
            lib.toggleFavorite(anime.id);
          }
        });
        break;
      default:
        break; // left / bottom = skip
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: BackdropGlow()),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(child: _deck()),
                _actions(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientText(l.t('nav_discover'),
                  style: AppTheme.display(30, weight: FontWeight.w800)),
              Text(l.t('discover_subtitle'),
                  style: TextStyle(color: AppColors.textMid, fontSize: 13)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Icon(Icons.style_rounded,
                    color: AppColors.primaryBright, size: 16),
                const SizedBox(width: 6),
                Text('${_cards.length}',
                    style: AppTheme.display(14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deck() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    final l = AppLocalizations.of(context);
    if (_error) {
      return _message(
        icon: Icons.wifi_off_rounded,
        title: l.t('conn_trouble'),
        subtitle: l.t('conn_trouble_sub'),
        onTap: () {
          AdGate.onTap();
          _loadBatch(initial: true);
        },
      );
    }
    if (_cards.isEmpty) {
      return _message(
        icon: Icons.done_all_rounded,
        title: l.t('caught_up'),
        subtitle: l.t('caught_up_sub'),
        onTap: () {
          AdGate.onTap();
          _loadBatch(initial: true);
        },
      );
    }
    return CardSwiper(
      key: ValueKey(_deckKey),
      controller: _controller,
      cardsCount: _cards.length,
      numberOfCardsDisplayed: math.min(3, _cards.length),
      isLoop: false,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      backCardOffset: const Offset(0, 44),
      scale: 0.92,
      allowedSwipeDirection: const AllowedSwipeDirection.only(
          left: true, right: true, up: true),
      onSwipe: (prev, curr, dir) {
        _onSwipe(prev, dir);
        return true;
      },
      onEnd: () => _loadBatch(),
      cardBuilder: (context, index, hOff, vOff) {
        return _SwipeCard(anime: _cards[index], hOffset: hOff, vOffset: vOff);
      },
    );
  }

  Widget _actions() {
    if (_cards.isEmpty || _loading) return const SizedBox(height: 72);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionButton(
            icon: Icons.close_rounded,
            color: AppColors.danger,
            size: 58,
            onTap: () {
              AdGate.onTap();
              _controller.swipe(CardSwiperDirection.left);
            },
          ),
          const SizedBox(width: 18),
          _ActionButton(
            icon: Icons.favorite_rounded,
            color: AppColors.accent,
            size: 46,
            onTap: () {
              AdGate.onTap();
              _controller.swipe(CardSwiperDirection.top);
            },
          ),
          const SizedBox(width: 18),
          _ActionButton(
            icon: Icons.info_outline_rounded,
            color: AppColors.cyan,
            size: 46,
            onTap: () {
              if (_cards.isEmpty) return;
              // Open detail for the visually top-most card.
              AdGate.onTap();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AnimeDetailScreen(anime: _cards.first)));
            },
          ),
          const SizedBox(width: 18),
          _ActionButton(
            icon: Icons.bookmark_added_rounded,
            color: AppColors.success,
            size: 58,
            onTap: () {
              AdGate.onTap();
              _controller.swipe(CardSwiperDirection.right);
            },
          ),
        ],
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textLow),
            const SizedBox(height: 16),
            Text(title, style: AppTheme.display(20)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textMid, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.42),
      ),
    );
  }
}

/// A single full-bleed poster card with swipe-intent overlays.
class _SwipeCard extends StatelessWidget {
  final Anime anime;
  final int hOffset;
  final int vOffset;
  const _SwipeCard({
    required this.anime,
    required this.hOffset,
    required this.vOffset,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkPoster(url: anime.imageUrl),
          const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.posterScrim)),
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ScoreBadge(anime.score, fontSize: 13),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(anime.yearSeasonLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  anime.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(26, weight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (anime.genres.isNotEmpty)
                  Text(
                    anime.genres.take(3).join('  Â·  '),
                    style: TextStyle(
                        color: AppColors.textMid,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          // Swipe-intent stamps.
          _stamp(
            visible: hOffset > 18,
            align: Alignment.topLeft,
            label: l.t('want'),
            color: AppColors.success,
            angle: -0.3,
          ),
          _stamp(
            visible: hOffset < -18,
            align: Alignment.topRight,
            label: l.t('skip'),
            color: AppColors.danger,
            angle: 0.3,
          ),
          _stamp(
            visible: vOffset < -18 && hOffset.abs() < 18,
            align: Alignment.topCenter,
            label: l.t('love'),
            color: AppColors.accent,
            angle: 0,
          ),
        ],
      ),
    );
  }

  Widget _stamp({
    required bool visible,
    required Alignment align,
    required String label,
    required Color color,
    required double angle,
  }) {
    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: Transform.rotate(
            angle: angle,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 3),
                borderRadius: BorderRadius.circular(12),
                color: color.withValues(alpha: 0.15),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/anime.dart';
import '../services/jikan_api.dart';
import '../services/ad_gate.dart';
import '../theme/app_theme.dart';
import '../widgets/network_poster.dart';
import '../widgets/poster_tile.dart';
import '../widgets/ui_kit.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Anime>? _trending;
  List<Anime>? _topScored;
  List<Anime>? _season;

  String _query = '';
  GenreFilter? _genre;
  List<Anime> _results = [];
  bool _busy = false;

  bool get _filtering => _query.isNotEmpty || _genre != null;

  @override
  void initState() {
    super.initState();
    _loadCurated();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurated() async {
    try {
      final t = await JikanApi.instance.trending();
      if (mounted) setState(() => _trending = t);
      final s = await JikanApi.instance.seasonNow();
      if (mounted) setState(() => _season = s);
      final r = await JikanApi.instance.topScored();
      if (mounted) setState(() => _topScored = r);
    } catch (_) {
      // Network/API unreachable — show the bundled offline titles instead
      // of leaving the curated rails permanently empty.
      final fallback = await JikanApi.instance.fallback().catchError((_) {
        return <Anime>[];
      });
      if (mounted) {
        setState(() {
          _trending ??= fallback;
          _season ??= fallback;
          _topScored ??= fallback;
        });
      }
    }
  }

  Future<void> _runSearch(String q) async {
    setState(() {
      _query = q.trim();
      _genre = null;
      _busy = true;
      _results = [];
    });
    if (_query.isEmpty) {
      setState(() => _busy = false);
      return;
    }
    try {
      final r = await JikanApi.instance.search(_query);
      if (mounted && _query == q.trim()) {
        setState(() {
          _results = r;
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectGenre(GenreFilter g) async {
    final toggledOff = _genre?.id == g.id;
    setState(() {
      _genre = toggledOff ? null : g;
      _query = '';
      _searchCtrl.clear();
      _results = [];
      _busy = !toggledOff;
    });
    if (toggledOff) return;
    try {
      final r = await JikanApi.instance.byGenre(g.id);
      if (mounted && _genre?.id == g.id) {
        setState(() {
          _results = r;
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GradientText(l.t('nav_explore'),
                    style: AppTheme.display(30, weight: FontWeight.w800)),
              ),
            ),
            _searchBar(),
            const SizedBox(height: 12),
            _genreRow(),
            const SizedBox(height: 8),
            Expanded(
              child: _filtering ? _resultsView() : _curatedView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        child: TextField(
          controller: _searchCtrl,
          textInputAction: TextInputAction.search,
          onSubmitted: (q) {
            AdGate.onTap();
            _runSearch(q);
          },
          style: TextStyle(color: AppColors.textHigh),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).t('search_hint'),
            hintStyle: TextStyle(color: AppColors.textLow),
            prefixIcon:
                Icon(Icons.search_rounded, color: AppColors.textMid),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textMid),
                    onPressed: () {
                      AdGate.onTap();
                      _searchCtrl.clear();
                      _runSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _genreRow() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: GenreFilter.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final g = GenreFilter.all[i];
          return GenreChip(
            g.name,
            selected: _genre?.id == g.id,
            onTap: () {
              AdGate.onTap();
              _selectGenre(g);
            },
          );
        },
      ),
    );
  }

  Widget _curatedView() {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _Rail(title: l.t('trending_now'), items: _trending),
        _Rail(title: l.t('this_season'), items: _season),
        _Rail(title: l.t('top_rated'), items: _topScored),
      ],
    );
  }

  Widget _resultsView() {
    if (_busy) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 52, color: AppColors.textLow),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context).t('no_results'),
                style: AppTheme.display(18)),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final cross = (c.maxWidth / 128).floor().clamp(3, 6);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: _results.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            childAspectRatio: 0.52,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
          ),
          itemBuilder: (_, i) =>
              PosterTile(anime: _results[i], width: double.infinity),
        );
      },
    );
  }
}

/// A titled horizontal scroller of posters.
class _Rail extends StatelessWidget {
  final String title;
  final List<Anime>? items;
  const _Rail({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        SizedBox(
          height: 244,
          child: items == null
              ? _loadingRail()
              : items!.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items!.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => PosterTile(anime: items![i]),
                    ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _loadingRail() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (_, __) => SizedBox(
        width: 132,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const PosterShimmer(),
          ),
        ),
      ),
    );
  }
}

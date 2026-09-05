import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/tracked_anime.dart';
import '../models/watch_status.dart';
import '../services/library_service.dart';
import '../theme/app_theme.dart';
import '../widgets/network_poster.dart';
import '../widgets/track_sheet.dart';
import '../widgets/ui_kit.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  WatchStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lib = context.watch<LibraryService>();
    final items =
        _filter == null ? lib.all : lib.byStatus(_filter!);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(
                children: [
                  GradientText(l.t('my_library'),
                      style: AppTheme.display(30, weight: FontWeight.w800)),
                  const Spacer(),
                  Text('${lib.all.length} ${l.t('titles')}',
                      style: TextStyle(
                          color: AppColors.textMid, fontSize: 13)),
                ],
              ),
            ),
            _filterRow(lib),
            const SizedBox(height: 6),
            Expanded(
              child: items.isEmpty
                  ? _empty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _LibraryRow(tracked: items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterRow(LibraryService lib) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          GenreChip(l.t('filter_all'),
              selected: _filter == null,
              onTap: () => setState(() => _filter = null)),
          for (final s in WatchStatus.values) ...[
            const SizedBox(width: 8),
            GenreChip(
              '${l.status(s, short: true)} ${lib.countByStatus(s)}',
              selected: _filter == s,
              onTap: () => setState(() => _filter = s),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty() {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.collections_bookmark_rounded,
              size: 56, color: AppColors.textLow),
          const SizedBox(height: 14),
          Text(l.t('nothing_here'), style: AppTheme.display(19)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              l.t('nothing_here_sub'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMid, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  final TrackedAnime tracked;
  const _LibraryRow({required this.tracked});

  @override
  Widget build(BuildContext context) {
    final lib = context.read<LibraryService>();
    final total = tracked.totalEpisodes;
    return GestureDetector(
      onTap: () => showTrackSheet(context, animeFromTracked(tracked)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: NetworkPoster(
                  url: tracked.imageUrl, width: 58, height: 80),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tracked.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.textHigh,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statusChip(AppLocalizations.of(context)),
                      const SizedBox(width: 8),
                      if (tracked.userRating > 0) ...[
                        const Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 14),
                        Text(' ${tracked.userRating.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                      if (tracked.favorite) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.favorite_rounded,
                            color: AppColors.accent, size: 13),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: tracked.progressFraction,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceHigh,
                            valueColor: AlwaysStoppedAnimation(
                                tracked.status.color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${tracked.progress}${total != null ? '/$total' : ''}',
                        style: TextStyle(
                            color: AppColors.textMid,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (tracked.status == WatchStatus.watching ||
                tracked.status == WatchStatus.planned)
              GestureDetector(
                onTap: () => lib.incrementProgress(tracked.id),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 22),
                ),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textLow),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tracked.status.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tracked.status.icon, size: 12, color: tracked.status.color),
          const SizedBox(width: 4),
          Text(
            l.status(tracked.status, short: true),
            style: TextStyle(
                color: tracked.status.color,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

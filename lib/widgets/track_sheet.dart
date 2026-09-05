import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/anime.dart';
import '../models/tracked_anime.dart';
import '../models/watch_status.dart';
import '../services/library_service.dart';
import '../theme/app_theme.dart';
import 'network_poster.dart';
import 'ui_kit.dart';

/// Builds a lightweight [Anime] from a stored library item so the track sheet
/// can be reused from screens that only hold a [TrackedAnime].
Anime animeFromTracked(TrackedAnime t) => Anime(
      id: t.id,
      title: t.title,
      imageUrl: t.imageUrl,
      episodes: t.totalEpisodes,
      score: t.communityScore,
      genres: t.genres,
      type: t.type,
    );

/// Opens the add / edit tracking sheet for a given anime.
Future<void> showTrackSheet(BuildContext context, Anime anime) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TrackSheet(anime: anime),
  );
}

class _TrackSheet extends StatelessWidget {
  final Anime anime;
  const _TrackSheet({required this.anime});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lib = context.watch<LibraryService>();
    final tracked = lib.get(anime.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.stroke)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLow,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: NetworkPoster(
                    url: anime.imageUrl, width: 54, height: 74),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.display(17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${anime.type} Â· ${anime.episodesLabel} eps',
                      style: TextStyle(
                          color: AppColors.textMid, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (tracked != null)
                IconButton(
                  icon: Icon(
                    tracked.favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: tracked.favorite
                        ? AppColors.accent
                        : AppColors.textMid,
                  ),
                  onPressed: () => lib.toggleFavorite(anime.id),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(l.t('ts_status'),
              style: TextStyle(
                  color: AppColors.textMid,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in WatchStatus.values)
                _StatusPill(
                  status: s,
                  selected: tracked?.status == s,
                  onTap: () => lib.addFromAnime(anime, s),
                ),
            ],
          ),
          if (tracked != null) ...[
            const SizedBox(height: 24),
            _ProgressControl(tracked: tracked),
            const SizedBox(height: 22),
            _RatingControl(tracked: tracked),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: BrandButton(
                    label: l.t('ts_done'),
                    icon: Icons.check_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                _RemoveButton(id: anime.id),
              ],
            ),
          ] else ...[
            const SizedBox(height: 24),
            Text(
              l.t('ts_pick'),
              style: TextStyle(
                  color: AppColors.textLow, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final WatchStatus status;
  final bool selected;
  final VoidCallback onTap;
  const _StatusPill(
      {required this.status, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? status.color.withValues(alpha: 0.18)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? status.color : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon,
                size: 17,
                color: selected ? status.color : AppColors.textMid),
            const SizedBox(width: 7),
            Text(
              AppLocalizations.of(context).status(status, short: true),
              style: TextStyle(
                color: selected ? status.color : AppColors.textMid,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressControl extends StatelessWidget {
  final TrackedAnime tracked;
  const _ProgressControl({required this.tracked});

  @override
  Widget build(BuildContext context) {
    final lib = context.read<LibraryService>();
    final total = tracked.totalEpisodes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context).t('ts_progress'),
                style: TextStyle(
                    color: AppColors.textMid,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const Spacer(),
            Text(
              '${tracked.progress}${total != null ? ' / $total' : ''}',
              style: AppTheme.display(15),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _RoundIcon(
              icon: Icons.remove_rounded,
              onTap: () => lib.setProgress(tracked.id, tracked.progress - 1),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: tracked.progressFraction,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceHigh,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primaryBright),
                ),
              ),
            ),
            const SizedBox(width: 14),
            _RoundIcon(
              icon: Icons.add_rounded,
              onTap: () => lib.incrementProgress(tracked.id),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.textHigh, size: 20),
      ),
    );
  }
}

class _RatingControl extends StatelessWidget {
  final TrackedAnime tracked;
  const _RatingControl({required this.tracked});

  @override
  Widget build(BuildContext context) {
    final lib = context.read<LibraryService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context).t('ts_rating'),
                style: TextStyle(
                    color: AppColors.textMid,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const Spacer(),
            Text(
              tracked.userRating == 0
                  ? AppLocalizations.of(context).t('ts_not_rated')
                  : tracked.userRating.toStringAsFixed(0),
              style: AppTheme.display(15,
                  color: tracked.userRating == 0
                      ? AppColors.textLow
                      : AppColors.gold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (int i = 1; i <= 10; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => lib.setRating(
                      tracked.id, i == tracked.userRating ? 0 : i.toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Icon(
                      i <= tracked.userRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i <= tracked.userRating
                          ? AppColors.gold
                          : AppColors.textLow,
                      size: 22,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final int id;
  const _RemoveButton({required this.id});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<LibraryService>().remove(id);
        Navigator.pop(context);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger),
      ),
    );
  }
}

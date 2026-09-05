import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/anime.dart';
import '../screens/detail_screen.dart';
import '../services/library_service.dart';
import '../theme/app_theme.dart';
import 'network_poster.dart';
import 'ui_kit.dart';

/// A tappable poster used across grids and horizontal rails.
class PosterTile extends StatelessWidget {
  final Anime anime;
  final double width;
  const PosterTile({super.key, required this.anime, this.width = 132});

  @override
  Widget build(BuildContext context) {
    final tracked = context.select<LibraryService, bool>(
        (l) => l.isTracked(anime.id));

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AnimeDetailScreen(anime: anime)),
      ),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'poster-${anime.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: NetworkPoster(url: anime.imageUrl),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: ScoreBadge(anime.score),
                  ),
                  if (tracked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          gradient: AppColors.brand,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bookmark_rounded,
                            color: Colors.white, size: 13),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              anime.displayTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textHigh,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              anime.yearSeasonLabel,
              style: TextStyle(color: AppColors.textLow, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

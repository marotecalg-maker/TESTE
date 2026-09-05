import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/catalog_anime.dart';
import '../providers/anime_provider.dart';
import 'episode_list.dart';
import 'ui_kit.dart';

/// The "Watch" entry point that bridges a tracked (Jikan) anime to the bundled
/// catalog's playable episodes.
///
/// It plays the next episode the viewer hasn't watched yet (the first episode
/// on a fresh start), so it doubles as a "continue watching" shortcut. Browsing
/// and picking a specific episode is handled by [EpisodesSection] on the detail
/// screen. This widget lives outside the detail screen so that screen never has
/// to import the catalog's `Anime` model alongside its own.
class WatchButton extends StatelessWidget {
  const WatchButton({super.key, required this.match, required this.heroTitle});

  /// The catalog entry (with episodes + servers) matched to the shown anime.
  final Anime match;

  /// Title shown in the player app bar.
  final String heroTitle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BrandButton(
      label: l.t('watch_now'),
      icon: Icons.play_arrow_rounded,
      onTap: () => _onTap(context),
    );
  }

  void _onTap(BuildContext context) {
    final episodes = playableEpisodes(match);
    if (episodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('no_episodes'))),
      );
      return;
    }
    final provider = context.read<AnimeProvider>();
    final key = match.title ?? heroTitle;
    // Resume on the first not-yet-watched episode; fall back to the first.
    final next = episodes.firstWhere(
      (e) => !provider.isEpisodeWatched(key, e.number ?? ''),
      orElse: () => episodes.first,
    );
    openEpisodePlayer(context,
        match: match, heroTitle: heroTitle, episode: next);
  }
}

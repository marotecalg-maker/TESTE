import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/aura_engine.dart';
import '../services/library_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'aura_screen.dart';
import 'settings_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final stats = context.watch<LibraryService>().stats;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: BackdropGlow()),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                Row(
                  children: [
                    GradientText(l.t('your_journey'),
                        style: AppTheme.display(30, weight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.settings_rounded,
                          color: AppColors.textMid),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AuraCta(aura: Aura.from(stats), label: l.t('aura_reveal'),
                    subtitle: l.t('aura_subtitle')),
                const SizedBox(height: 18),
                _LevelCard(stats: stats),
                const SizedBox(height: 18),
                _statGrid(l, stats),
                const SizedBox(height: 26),
                if (stats.topGenres.isNotEmpty) ...[
                  Text(l.t('your_taste'), style: AppTheme.display(20)),
                  const SizedBox(height: 14),
                  _TasteChart(stats: stats),
                  const SizedBox(height: 26),
                ],
                Row(
                  children: [
                    Text(l.t('achievements'), style: AppTheme.display(20)),
                    const Spacer(),
                    Text(
                      '${stats.achievements.where((a) => a.unlocked).length}/${stats.achievements.length}',
                      style: TextStyle(
                          color: AppColors.textMid,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _AchievementsGrid(stats: stats),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statGrid(AppLocalizations l, AnimeStats s) {
    final tiles = [
      _StatData(Icons.play_circle_rounded, '${s.episodesWatched}',
          l.t('stat_episodes'), AppColors.cyan),
      _StatData(Icons.schedule_rounded, _hours(s), l.t('stat_watched'),
          AppColors.primaryBright),
      _StatData(Icons.check_circle_rounded, '${s.completed}',
          l.t('stat_completed'), AppColors.success),
      _StatData(
          Icons.star_rounded,
          s.avgRating == 0 ? 'â€”' : s.avgRating.toStringAsFixed(1),
          l.t('stat_avg'),
          AppColors.gold),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [for (final t in tiles) _StatTile(data: t)],
    );
  }

  static String _hours(AnimeStats s) {
    if (s.minutesWatched < 60) return '${s.minutesWatched}m';
    if (s.hoursWatched < 100) return '${s.hoursWatched.toStringAsFixed(1)}h';
    return '${s.hoursWatched.toStringAsFixed(0)}h';
  }
}

/// Entry card that opens the Kioku Aura reveal.
class _AuraCta extends StatelessWidget {
  final Aura aura;
  final String label;
  final String subtitle;
  const _AuraCta(
      {required this.aura, required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AuraScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: aura.colors),
          boxShadow: [
            BoxShadow(
              color: aura.colors.first.withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5), width: 1.5),
              ),
              child:
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.display(17, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final AnimeStats stats;
  const _LevelCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4), width: 2),
                ),
                child: Center(
                  child: Text('${stats.level}',
                      style: AppTheme.display(26,
                          weight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l.t('level').toUpperCase()} ${stats.level}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(stats.rankTitle,
                      style: AppTheme.display(22,
                          weight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${stats.xp} XP',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text('${stats.xpIntoLevel} / ${stats.xpForNextLevel}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: stats.levelProgress,
                  minHeight: 10,
                  backgroundColor: Colors.black.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  _StatData(this.icon, this.value, this.label, this.color);
}

class _StatTile extends StatelessWidget {
  final _StatData data;
  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, color: data.color, size: 24),
          const Spacer(),
          Text(data.value, style: AppTheme.display(24)),
          Text(data.label,
              style: TextStyle(
                  color: AppColors.textMid, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _TasteChart extends StatelessWidget {
  final AnimeStats stats;
  const _TasteChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final top = stats.topGenres;
    final max = top.first.value.toDouble();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          for (final e in top) ...[
            _bar(e.key, e.value, max),
            if (e != top.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _bar(String label, int value, double max) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.textHigh,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final w = (value / max).clamp(0.08, 1.0) * c.maxWidth;
              return Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    height: 12,
                    width: w,
                    decoration: BoxDecoration(
                      gradient: AppColors.brand,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 22,
          child: Text('$value',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  final AnimeStats stats;
  const _AchievementsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final list = stats.achievements;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.82,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, i) {
        final a = list[i];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: a.unlocked
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : AppColors.stroke,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: a.unlocked ? 1 : 0.35,
                child: Text(a.emoji, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(height: 6),
              Text(
                a.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: a.unlocked ? AppColors.textHigh : AppColors.textMid,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              if (a.unlocked)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 15)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: a.fraction,
                      minHeight: 4,
                      backgroundColor: AppColors.surfaceHigh,
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.primaryBright),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

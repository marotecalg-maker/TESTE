import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/aura_engine.dart';
import '../services/library_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Kioku Aura â€” the signature "taste DNA" reveal screen.
class AuraScreen extends StatefulWidget {
  const AuraScreen({super.key});

  @override
  State<AuraScreen> createState() => _AuraScreenState();
}

class _AuraScreenState extends State<AuraScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final aura = Aura.from(context.watch<LibraryService>().stats);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: BackdropGlow()),
          SafeArea(
            child: Column(
              children: [
                _header(l),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _AuraOrb(aura: aura, spin: _spin),
                        const SizedBox(height: 26),
                        _rarityBadge(l, aura),
                        const SizedBox(height: 14),
                        GradientText(
                          aura.name,
                          align: TextAlign.center,
                          style: AppTheme.display(32, weight: FontWeight.w900),
                          gradient: LinearGradient(colors: aura.colors),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          aura.empty ? l.t('aura_empty_cta') : aura.tagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 15,
                              height: 1.4),
                        ),
                        if (!aura.empty) ...[
                          const SizedBox(height: 28),
                          _traits(l, aura),
                          const SizedBox(height: 20),
                          _footer(l, aura),
                          const SizedBox(height: 18),
                          Text(
                            l.t('aura_share_hint'),
                            style: TextStyle(
                                color: AppColors.textLow, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          Text(l.t('your_aura'), style: AppTheme.display(22)),
        ],
      ),
    );
  }

  Widget _rarityBadge(AppLocalizations l, Aura aura) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: aura.rarityColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: aura.rarityColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 15, color: aura.rarityColor),
          const SizedBox(width: 6),
          Text(
            l.t('rarity_${aura.rarityKey}').toUpperCase(),
            style: TextStyle(
              color: aura.rarityColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _traits(AppLocalizations l, Aura aura) {
    return Column(
      children: [
        for (final key in Aura.traitOrder) ...[
          _TraitBar(
            label: l.t('trait_$key'),
            value: aura.traits[key] ?? 0,
            colors: aura.colors,
            dominant: key == aura.dominantKey,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _footer(AppLocalizations l, Aura aura) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _metric('${(aura.purity * 100).round()}%', l.t('aura_purity')),
              _divider(),
              _metric(
                  l.t('trait_${aura.dominantKey == 'balanced' ? 'wonder' : aura.dominantKey}'),
                  l.t('aura_dominant')),
              _divider(),
              _metric('${aura.titles}', l.t('aura_titles')),
            ],
          ),
          if (aura.topGenres.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l.t('aura_top_genres'),
                style: TextStyle(
                    color: AppColors.textMid,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final g in aura.topGenres) GenreChip(g)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.display(17)),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(color: AppColors.textLow, fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: AppColors.stroke,
      );
}

/// The animated aura â€” a slowly rotating sweep-gradient orb with a soft glow.
class _AuraOrb extends StatelessWidget {
  final Aura aura;
  final Animation<double> spin;
  const _AuraOrb({required this.aura, required this.spin});

  @override
  Widget build(BuildContext context) {
    const size = 220.0;
    final colors = [...aura.colors, aura.colors.first];
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: spin,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.92,
                height: size * 0.92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: aura.colors.first.withValues(alpha: 0.55),
                      blurRadius: 70,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: aura.colors.last.withValues(alpha: 0.35),
                      blurRadius: 90,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: spin.value * 2 * math.pi,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: colors),
                  ),
                ),
              ),
              // inner well
              Container(
                width: size * 0.58,
                height: size * 0.58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bg.withValues(alpha: 0.72),
                ),
              ),
              Transform.rotate(
                angle: -spin.value * math.pi,
                child: Icon(Icons.auto_awesome_rounded,
                    color: Colors.white.withValues(alpha: 0.9), size: 34),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TraitBar extends StatelessWidget {
  final String label;
  final double value;
  final List<Color> colors;
  final bool dominant;
  const _TraitBar({
    required this.label,
    required this.value,
    required this.colors,
    required this.dominant,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(
                      color: dominant ? AppColors.textHigh : AppColors.textMid,
                      fontSize: 13.5,
                      fontWeight:
                          dominant ? FontWeight.w800 : FontWeight.w500)),
              if (dominant) ...[
                const SizedBox(width: 4),
                Icon(Icons.star_rounded, size: 12, color: colors.first),
              ],
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              return Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    height: 12,
                    width: value.clamp(0.03, 1.0) * c.maxWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
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
          width: 34,
          child: Text('${(value * 100).round()}%',
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

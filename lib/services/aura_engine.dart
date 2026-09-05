import 'package:flutter/material.dart';

import 'library_service.dart';

/// Kioku Aura — a personal "taste DNA" computed from the user's library.
///
/// This is Kioku's signature original feature: no other tracker turns your
/// watch history into an archetype with a unique colour signature. It maps
/// the genres you watch onto four emotional traits, derives an archetype and
/// aura gradient, and grades a rarity from how much you've watched.
class Aura {
  final String name; // archetype, e.g. "The Dreamweaver"
  final String tagline; // short poetic line
  final List<Color> colors; // 2–3 stop aura gradient
  final Map<String, double> traits; // trait key -> 0..1 fraction
  final String dominantKey;
  final String secondaryKey;
  final String rarityKey;
  final double purity; // dominant trait share, 0..1
  final List<String> topGenres;
  final int titles;
  final bool empty;

  const Aura({
    required this.name,
    required this.tagline,
    required this.colors,
    required this.traits,
    required this.dominantKey,
    required this.secondaryKey,
    required this.rarityKey,
    required this.purity,
    required this.topGenres,
    required this.titles,
    this.empty = false,
  });

  /// Trait keys in a stable display order.
  static const List<String> traitOrder = ['intensity', 'wonder', 'heart', 'humor'];

  // Which trait each genre feeds. Genres not listed are treated as neutral.
  static const Map<String, String> _genreTrait = {
    'Action': 'intensity',
    'Sports': 'intensity',
    'Suspense': 'intensity',
    'Thriller': 'intensity',
    'Military': 'intensity',
    'Martial Arts': 'intensity',
    'Fantasy': 'wonder',
    'Sci-Fi': 'wonder',
    'Adventure': 'wonder',
    'Supernatural': 'wonder',
    'Mystery': 'wonder',
    'Space': 'wonder',
    'Magic': 'wonder',
    'Romance': 'heart',
    'Drama': 'heart',
    'Slice of Life': 'heart',
    'Josei': 'heart',
    'Shoujo': 'heart',
    'Comedy': 'humor',
    'Gourmet': 'humor',
    'Parody': 'humor',
  };

  static const Map<String, _Archetype> _archetypes = {
    'intensity': _Archetype(
      'The Firebrand',
      'Adrenaline is your language.',
      [Color(0xFFFF6B4D), Color(0xFFFF2D6F)],
    ),
    'wonder': _Archetype(
      'The Dreamweaver',
      'You chase worlds unknown.',
      [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
    ),
    'heart': _Archetype(
      'The Kindred',
      'You feel every story.',
      [Color(0xFFFF4D8D), Color(0xFFFF9DB8)],
    ),
    'humor': _Archetype(
      'The Trickster',
      'Here for the pure joy.',
      [Color(0xFFFFC24B), Color(0xFFFF8A5C)],
    ),
    'balanced': _Archetype(
      'The Wanderer',
      'A little of everything moves you.',
      [Color(0xFF22D3EE), Color(0xFF8B5CF6)],
    ),
  };

  factory Aura.from(AnimeStats stats) {
    if (stats.totalTracked == 0 || stats.genreCounts.isEmpty) {
      return const Aura(
        name: 'Blank Canvas',
        tagline: 'Your aura is waiting to be written.',
        colors: [Color(0xFF2A2140), Color(0xFF171021)],
        traits: {'intensity': 0, 'wonder': 0, 'heart': 0, 'humor': 0},
        dominantKey: 'balanced',
        secondaryKey: 'balanced',
        rarityKey: 'dormant',
        purity: 0,
        topGenres: [],
        titles: 0,
        empty: true,
      );
    }

    final weights = <String, double>{
      'intensity': 0,
      'wonder': 0,
      'heart': 0,
      'humor': 0,
    };
    for (final e in stats.genreCounts.entries) {
      final trait = _genreTrait[e.key];
      if (trait != null) weights[trait] = weights[trait]! + e.value;
    }
    final total = weights.values.fold<double>(0, (a, b) => a + b);
    final traits = <String, double>{};
    for (final k in traitOrder) {
      traits[k] = total == 0 ? 0 : weights[k]! / total;
    }

    // Sort traits to find dominant + secondary.
    final sorted = traits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dominant = sorted.first;
    final secondary = sorted.length > 1 ? sorted[1] : sorted.first;

    // "Balanced" if no trait clearly leads.
    final isBalanced = total == 0 || dominant.value < 0.34;
    final archKey = isBalanced ? 'balanced' : dominant.key;
    final arch = _archetypes[archKey]!;

    return Aura(
      name: arch.name,
      tagline: arch.tagline,
      colors: arch.colors,
      traits: traits,
      dominantKey: archKey,
      secondaryKey: secondary.key,
      rarityKey: _rarity(stats.episodesWatched),
      purity: dominant.value,
      topGenres: stats.topGenres.take(3).map((e) => e.key).toList(),
      titles: stats.totalTracked,
    );
  }

  static String _rarity(int episodes) {
    if (episodes >= 900) return 'mythic';
    if (episodes >= 400) return 'legendary';
    if (episodes >= 120) return 'epic';
    if (episodes >= 30) return 'rare';
    return 'awakening';
  }

  Color get rarityColor => switch (rarityKey) {
        'mythic' => const Color(0xFFFF4D8D),
        'legendary' => const Color(0xFFFFC24B),
        'epic' => const Color(0xFFA855F7),
        'rare' => const Color(0xFF22D3EE),
        _ => const Color(0xFF7E7394),
      };
}

class _Archetype {
  final String name;
  final String tagline;
  final List<Color> colors;
  const _Archetype(this.name, this.tagline, this.colors);
}

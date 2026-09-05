import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The personal tracking state a user assigns to an anime in their library.
enum WatchStatus {
  watching,
  completed,
  planned,
  onHold,
  dropped;

  String get label => switch (this) {
        WatchStatus.watching => 'Watching',
        WatchStatus.completed => 'Completed',
        WatchStatus.planned => 'Plan to Watch',
        WatchStatus.onHold => 'On Hold',
        WatchStatus.dropped => 'Dropped',
      };

  /// Short label used on compact chips.
  String get shortLabel => switch (this) {
        WatchStatus.watching => 'Watching',
        WatchStatus.completed => 'Completed',
        WatchStatus.planned => 'Planned',
        WatchStatus.onHold => 'On Hold',
        WatchStatus.dropped => 'Dropped',
      };

  Color get color => switch (this) {
        WatchStatus.watching => AppColors.cyan,
        WatchStatus.completed => AppColors.success,
        WatchStatus.planned => AppColors.primaryBright,
        WatchStatus.onHold => AppColors.gold,
        WatchStatus.dropped => AppColors.danger,
      };

  IconData get icon => switch (this) {
        WatchStatus.watching => Icons.play_circle_rounded,
        WatchStatus.completed => Icons.check_circle_rounded,
        WatchStatus.planned => Icons.bookmark_rounded,
        WatchStatus.onHold => Icons.pause_circle_rounded,
        WatchStatus.dropped => Icons.cancel_rounded,
      };

  String get storageKey => name;

  static WatchStatus fromKey(String? key) {
    return WatchStatus.values.firstWhere(
      (s) => s.name == key,
      orElse: () => WatchStatus.planned,
    );
  }
}

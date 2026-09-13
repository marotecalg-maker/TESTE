import 'package:flutter/material.dart';

import '../ads/src/networks/ads.dart';
import '../ads/src/widgets/custom_banner.dart';
import '../services/ad_gate.dart';

/// A bottom banner slot. Collapses to nothing while the remote config has no
/// banner network, so screens can place it unconditionally.
class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key, required this.slot});

  /// Stable name for this placement ("home", "detail"); the SDK keys its
  /// loaded banners by it.
  final String slot;

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  // Picked once: the network getter rotates on every read.
  late final Ads _ads = AdGate.banner;

  @override
  Widget build(BuildContext context) {
    if (!AdGate.bannersEnabled) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 50,
        child: CustomBanner(key: ValueKey('banner-${widget.slot}'), ads: _ads),
      ),
    );
  }
}

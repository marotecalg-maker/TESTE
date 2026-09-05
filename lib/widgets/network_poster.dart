import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

/// A cached cover image with a branded shimmer placeholder and a graceful
/// fallback tile when an image is missing or fails to load.
class NetworkPoster extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const NetworkPoster({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, _) => const PosterShimmer(),
      errorWidget: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceHigh,
      child: Center(
        child: Icon(Icons.image_not_supported_rounded,
            color: AppColors.textLow, size: 32),
      ),
    );
  }
}

class PosterShimmer extends StatelessWidget {
  const PosterShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceHigh,
      highlightColor: AppColors.surface,
      child: Container(color: AppColors.surfaceHigh),
    );
  }
}

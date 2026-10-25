import 'package:flutter/material.dart';

import '../data/service_photo.dart';
import '../models/models.dart';

/// Decode only the pixels the circle needs (at most 256, matching the asset).
int serviceImageCacheSize(BuildContext context, double logical) {
  final pixels = (logical * MediaQuery.devicePixelRatioOf(context)).round();
  if (pixels < 64) return 64;
  if (pixels > 256) return 256;
  return pixels;
}

class ServiceArtwork extends StatelessWidget {
  const ServiceArtwork({
    super.key,
    required this.category,
    this.height = 48,
    this.width,
    this.borderRadius = 12,
  });

  final ServiceCategory category;
  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final asset = category.imageAsset;
    if (asset == null) {
      return CircleAvatar(
        radius: height / 2,
        backgroundColor: category.color.withValues(alpha: 0.12),
        child: Icon(category.icon, size: height * 0.54, color: category.color),
      );
    }
    final side = width != null && width!.isFinite ? width! : height;
    final radius = borderRadius <= 0 ? 0.0 : side / 2;
    final cache = serviceImageCacheSize(context, side);
    final key = Key('service-image-${category.id}');
    final uploaded = servicePhotoBytes(asset);
    final fallback = ColoredBox(
      color: category.color.withValues(alpha: 0.12),
      child: SizedBox(
        width: side,
        height: height,
        child: Icon(category.icon, color: category.color),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: uploaded == null
          ? Image.asset(
              asset,
              key: key,
              width: side,
              height: height,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              cacheWidth: cache,
              cacheHeight: cache,
              semanticLabel: category.title,
              errorBuilder: (context, error, stackTrace) => fallback,
            )
          : Image.memory(
              uploaded,
              key: key,
              width: side,
              height: height,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              cacheWidth: cache,
              cacheHeight: cache,
              semanticLabel: category.title,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
    );
  }
}

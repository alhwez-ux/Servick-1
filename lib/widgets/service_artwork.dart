import 'package:flutter/material.dart';

import '../models/models.dart';

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        asset,
        key: Key('service-image-${category.id}'),
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: category.title,
        errorBuilder: (context, error, stackTrace) {
          return ColoredBox(
            color: category.color.withValues(alpha: 0.12),
            child: SizedBox(
              width: width,
              height: height,
              child: Icon(category.icon, color: category.color),
            ),
          );
        },
      ),
    );
  }
}

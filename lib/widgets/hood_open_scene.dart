import 'package:flutter/material.dart';

class HoodOpenScene extends StatelessWidget {
  const HoodOpenScene({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.asset(
          'assets/brand/hood_open.jpg',
          fit: BoxFit.cover,
          semanticLabel: 'مركبة متوقفة وغطاء المحرك مفتوح',
        ),
      ),
    );
    if (onTap == null) return image;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('hood-open-scene'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: image,
      ),
    );
  }
}

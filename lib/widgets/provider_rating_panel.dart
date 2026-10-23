import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/models.dart';
import '../theme/servick_theme.dart';

class ProviderRatingPanel extends StatefulWidget {
  const ProviderRatingPanel({super.key, required this.requestId});

  final String requestId;

  @override
  State<ProviderRatingPanel> createState() => _ProviderRatingPanelState();
}

class _ProviderRatingPanelState extends State<ProviderRatingPanel> {
  final _commentController = TextEditingController();
  var _stars = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    final error = AppScope.of(context).submitRating(
      requestId: widget.requestId,
      stars: _stars,
      comment: _commentController.text,
    );
    if (error != null) {
      _snack(error);
      return;
    }
    _snack('تم حفظ تقييمك لمقدم الخدمة');
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final request = model.requestById(widget.requestId);
    if (request == null || request.technicianId == null) {
      return const SizedBox.shrink();
    }
    if (request.status == RequestStatus.waiting) {
      return const SizedBox.shrink();
    }

    final saved = model.ratingForRequest(request.id);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ServickColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: saved == null
            ? _RatingForm(
                stars: _stars,
                commentController: _commentController,
                onStar: (value) => setState(() => _stars = value),
                onSubmit: _submit,
              )
            : _SavedRating(rating: saved),
      ),
    );
  }
}

class _RatingForm extends StatelessWidget {
  const _RatingForm({
    required this.stars,
    required this.commentController,
    required this.onStar,
    required this.onSubmit,
  });

  final int stars;
  final TextEditingController commentController;
  final ValueChanged<int> onStar;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'قيّم مقدم الخدمة',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text(
          'من نجمة إلى خمس. يظهر التقييم في صفحة الفني داخل هذه الجلسة.',
          style: TextStyle(color: ServickColors.muted, height: 1.5),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                key: Key('rating-star-$star'),
                tooltip: '$star',
                onPressed: () => onStar(star),
                icon: Icon(
                  star <= stars
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: ServickColors.amber,
                  size: 32,
                ),
              ),
          ],
        ),
        TextField(
          key: const Key('rating-comment'),
          controller: commentController,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'تعليقك (اختياري)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('submit-rating'),
          onPressed: onSubmit,
          child: const Text('أرسل التقييم'),
        ),
      ],
    );
  }
}

class _SavedRating extends StatelessWidget {
  const _SavedRating({required this.rating});

  final ProviderRating rating;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تم حفظ تقييمك',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              Icon(
                star <= rating.stars
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: ServickColors.amber,
                size: 22,
              ),
            const SizedBox(width: 8),
            Text(
              '${rating.stars} من 5',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(rating.comment, key: const Key('saved-rating-comment')),
      ],
    );
  }
}

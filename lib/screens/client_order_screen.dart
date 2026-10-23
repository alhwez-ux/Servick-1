import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/order_categories.dart';
import '../models/models.dart';
import '../theme/servick_theme.dart';
import '../widgets/privacy_gate.dart';

class ClientOrderScreen extends StatefulWidget {
  const ClientOrderScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  final String clientId;
  final String clientName;

  @override
  State<ClientOrderScreen> createState() => _ClientOrderScreenState();
}

class _ClientOrderScreenState extends State<ClientOrderScreen> {
  final _notesController = TextEditingController();
  String? _selectedCategoryId;
  String _selectedCity = cities.first;
  var _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitOrder() async {
    if (_selectedCategoryId == null) {
      _snack('الرجاء اختيار نوع الخدمة المطلوبة أولاً');
      return;
    }
    final allowed = await requireClientPrivacy(context);
    if (!allowed || !mounted) return;

    setState(() => _isLoading = true);
    final error = AppScope.of(context).submitClientOrder(
      clientId: widget.clientId,
      clientName: widget.clientName,
      categoryId: _selectedCategoryId!,
      city: _selectedCity,
      notes: _notesController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      _snack('حدث خطأ أثناء إرسال الطلب: $error');
      return;
    }

    final screenNavigator = Navigator.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'تم إرسال طلبك بنجاح',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.green),
          ),
          content: const Text(
            'تم نشر طلبك إلى أقرب الحرفيين المتاحين في منطقتك. سيتم إشعارك فور قبول الحرفي للطلب وتوجهه إليك.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            FilledButton(
              key: const Key('order-success-ok'),
              style: FilledButton.styleFrom(
                backgroundColor: ServickColors.navy,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                screenNavigator.pop();
              },
              child: const Text('حسناً'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'طلب خدمة صيانة عاجلة | Servick',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 15),
        ),
        backgroundColor: ServickColors.navy,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'الطلب باسم ${widget.clientName}',
                style: const TextStyle(color: ServickColors.muted, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'حدد موقعك الحالي:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('order-city'),
                initialValue: _selectedCity,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: ServickColors.emergency,
                  ),
                ),
                items: [
                  for (final city in cities)
                    DropdownMenuItem(value: city, child: Text(city)),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedCity = value);
                        }
                      },
              ),
              const SizedBox(height: 20),
              const Text(
                'اختر نوع التخصص المطلوب:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              for (final category in orderCategories) ...[
                _CategoryTile(
                  category: category,
                  selected: _selectedCategoryId == category.id,
                  onTap: _isLoading
                      ? null
                      : () => setState(() => _selectedCategoryId = category.id),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              TextField(
                key: const Key('order-notes'),
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'وصف العطل',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'يصل الطلب معلّقاً للحرفيين في مدينتك. لا يُرسل إلى خادم خارجي.',
                style: TextStyle(
                  color: ServickColors.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('submit-client-order'),
                  onPressed: _isLoading
                      ? null
                      : () {
                          _submitOrder();
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('إرسال الطلب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final OrderCategory category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? ServickColors.navy : ServickColors.line,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        key: Key('order-cat-${category.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(category.icon, color: ServickColors.navy),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: ServickColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../data/format.dart';
import '../data/service_pictures.dart';
import '../theme/servick_theme.dart';
import '../widgets/confirm_action.dart';
import '../widgets/service_artwork.dart';

class AdminServiceScreen extends StatefulWidget {
  const AdminServiceScreen({super.key});

  @override
  State<AdminServiceScreen> createState() => _AdminServiceScreenState();
}

class _AdminServiceScreenState extends State<AdminServiceScreen> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  var _pictureId = servicePictures.first.id;
  var _pictureLocked = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(_syncPicture);
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  void _syncPicture() {
    if (_pictureLocked) return;
    final next = pictureForTitle(_title.text).id;
    if (next == _pictureId) return;
    setState(() => _pictureId = next);
  }

  Future<void> _deleteService(String id) async {
    final approved = await confirmAction(
      context,
      title: 'حذف الخدمة',
      message: 'تُحذف الخدمة من كل الأجهزة. لا يعود هذا إلا بإضافتها من جديد.',
      confirm: 'حذف الخدمة',
    );
    if (!approved || !mounted) return;
    final error = AppScope.of(context).removeService(id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _save() {
    final error = AppScope.of(context).addService(
      title: _title.text,
      subtitle: _subtitle.text,
      pictureId: _pictureId,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'تمت إضافة الخدمة وتظهر الآن في الرئيسية'),
      ),
    );
    if (error == null) {
      _title.clear();
      _subtitle.clear();
      setState(() {
        _pictureLocked = false;
        _pictureId = servicePictures.first.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final added = AppScope.of(context).addedServices;
    final selected = servicePictureById(_pictureId);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إضافة خدمة جديدة',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const Text(
                  'الخدمة تُحفظ على الويب وتظهر في الرئيسية من أي جهاز. تُختار صورة حسب الاسم، ويمكن تغييرها قبل الحفظ. لا تُحذف إلا من هنا.',
                  style: TextStyle(height: 1.6, color: ServickColors.muted),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('service-title'),
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'اسم الخدمة',
                    hintText: 'مثال: صيانة مكيفات السيارات',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'صورة الخدمة: ${selected.label}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: servicePictures.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final picture = servicePictures[index];
                      final chosen = picture.id == _pictureId;
                      final thumb = serviceImageCacheSize(context, 76);
                      return InkWell(
                        key: Key('picture-${picture.id}'),
                        onTap: () {
                          setState(() {
                            _pictureLocked = true;
                            _pictureId = picture.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 84,
                          height: 84,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: chosen
                                  ? ServickColors.navy
                                  : ServickColors.line,
                              width: chosen ? 3 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              picture.asset,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.low,
                              cacheWidth: thumb,
                              cacheHeight: thumb,
                              semanticLabel: picture.label,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('service-subtitle'),
                  controller: _subtitle,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: serviceSubtitleMaxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  decoration: const InputDecoration(
                    labelText: 'وصف مختصر',
                    alignLabelWithHint: true,
                  ),
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        required maxLength,
                      }) {
                        final max = maxLength ?? serviceSubtitleMaxLength;
                        final nearLimit = currentLength >= max - 10;
                        return Text(
                          '${isolateLtr('$currentLength/$max')} حرفاً',
                          key: const Key('subtitle-count'),
                          style: TextStyle(
                            color: nearLimit
                                ? ServickColors.amber
                                : ServickColors.muted,
                            fontWeight: nearLimit
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        );
                      },
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('save-service'),
                  onPressed: _save,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة خدمة جديدة'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'الخدمات المضافة',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (added.isEmpty)
                  const Text(
                    'لم تُضف خدمة بعد.',
                    key: Key('added-services-empty'),
                    style: TextStyle(color: ServickColors.muted, height: 1.5),
                  )
                else
                  for (final service in added)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ServiceArtwork(category: service, height: 48),
                        title: Text(
                          service.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          service.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          key: Key('delete-service-${service.id}'),
                          tooltip: 'حذف الخدمة',
                          onPressed: () => _deleteService(service.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

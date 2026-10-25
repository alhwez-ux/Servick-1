import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../data/format.dart';
import '../data/service_photo.dart';
import '../data/service_pictures.dart';
import '../models/models.dart';
import '../theme/servick_theme.dart';
import '../widgets/confirm_action.dart';
import '../widgets/service_artwork.dart';

Future<Uint8List?> pickServiceImageFromDevice() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return null;
  return result.files.single.bytes;
}

class AdminServiceScreen extends StatefulWidget {
  const AdminServiceScreen({super.key, this.pickImage});

  final Future<Uint8List?> Function()? pickImage;

  @override
  State<AdminServiceScreen> createState() => _AdminServiceScreenState();
}

class _AdminServiceScreenState extends State<AdminServiceScreen> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  var _pictureId = servicePictures.first.id;
  var _pictureLocked = false;
  var _cleared = false;
  String? _uploadData;
  var _picking = false;

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
    if (_pictureLocked || _uploadData != null || _cleared) return;
    final next = pictureForTitle(_title.text).id;
    if (next == _pictureId) return;
    setState(() => _pictureId = next);
  }

  void _snack(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPhoto({String? serviceId}) async {
    if (_picking) return;
    setState(() => _picking = true);
    Uint8List? raw;
    try {
      raw = await (widget.pickImage ?? pickServiceImageFromDevice)();
    } catch (_) {
      raw = null;
      _snack('تعذر فتح ملفات الجهاز');
    }
    if (!mounted) return;
    setState(() => _picking = false);
    if (raw == null) return;
    final jpeg = compressServicePhoto(raw);
    if (jpeg == null) {
      _snack('تعذر استخدام هذه الصورة. اختر JPG أو PNG أصغر من 8 م.ب.');
      return;
    }
    final uri = servicePhotoDataUri(jpeg);
    if (serviceId == null) {
      setState(() {
        _uploadData = uri;
        _cleared = false;
        _pictureLocked = true;
      });
      return;
    }
    final error = AppScope.of(context)
        .updateServicePhoto(serviceId, imageData: uri);
    _snack(error ?? 'تمت إضافة الصورة وتظهر الآن في الرئيسية');
  }

  Future<void> _removeSavedPhoto(String id) async {
    final approved = await confirmAction(
      context,
      title: 'إزالة الصورة',
      message:
          'تُزال صورة هذه الخدمة من كل الأجهزة. يمكنك إضافة صورة أخرى لاحقاً.',
      confirm: 'إزالة الصورة',
    );
    if (!approved || !mounted) return;
    final error = AppScope.of(context).updateServicePhoto(id, remove: true);
    _snack(error ?? 'أُزيلت صورة الخدمة');
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
      imageData: _uploadData,
      withoutImage: _cleared && _uploadData == null,
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
        _uploadData = null;
        _cleared = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final added = AppScope.of(context).addedServices;
    final selected = servicePictureById(_pictureId);
    final String? draftImage =
        _uploadData ?? (_cleared ? null : selected.asset);
    final draftLabel = _uploadData != null
        ? 'صورة من الجهاز'
        : _cleared
        ? 'بدون صورة'
        : selected.label;
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
                  'الخدمة تُحفظ على الويب وتظهر في الرئيسية من أي جهاز. أضف صورة من جهازك أو أزلها، أو اختر صورة جاهزة. الصورة المضافة تُضغط حتى تبقى خفيفة. لا تُحذف الخدمة إلا من هنا.',
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
                  'صورة الخدمة: $draftLabel',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Center(child: _DraftPhoto(imageAsset: draftImage)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('add-service-photo'),
                      onPressed: _picking ? null : () => _pickPhoto(),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('إضافة صورة'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('remove-service-photo'),
                      onPressed: draftImage == null
                          ? null
                          : () {
                              setState(() {
                                _uploadData = null;
                                _cleared = true;
                                _pictureLocked = true;
                              });
                            },
                      icon: const Icon(Icons.hide_image_outlined),
                      label: const Text('إزالة الصورة'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                            _uploadData = null;
                            _cleared = false;
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                        child: Column(
                          children: [
                            ListTile(
                              leading: ServiceArtwork(
                                category: service,
                                height: 48,
                              ),
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
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  key: Key('add-photo-${service.id}'),
                                  onPressed: _picking
                                      ? null
                                      : () => _pickPhoto(serviceId: service.id),
                                  icon: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                                  label: const Text('إضافة صورة'),
                                ),
                                TextButton.icon(
                                  key: Key('remove-photo-${service.id}'),
                                  onPressed: service.imageAsset == null
                                      ? null
                                      : () => _removeSavedPhoto(service.id),
                                  icon: const Icon(Icons.hide_image_outlined),
                                  label: const Text('إزالة الصورة'),
                                ),
                              ],
                            ),
                          ],
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

class _DraftPhoto extends StatelessWidget {
  const _DraftPhoto({required this.imageAsset});

  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    if (imageAsset == null) {
      return const SizedBox(
        key: Key('draft-photo-empty'),
        width: 84,
        height: 84,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFF4F6FB),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.image_outlined, color: ServickColors.muted),
        ),
      );
    }
    return ServiceArtwork(
      category: ServiceCategory(
        id: 'draft',
        title: 'صورة الخدمة',
        subtitle: '',
        icon: Icons.image_outlined,
        color: ServickColors.navy,
        imageAsset: imageAsset,
      ),
      height: 84,
      borderRadius: 42,
    );
  }
}

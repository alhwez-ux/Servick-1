import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const servicePhotoPrefix = 'data:image/jpeg;base64,';
const servicePhotoEdge = 256;
const servicePhotoMaxSourceBytes = 8 * 1024 * 1024;
const maxServicePhotoUriLength = 80000;

bool isUploadedServicePhoto(String? value) {
  return value != null && value.startsWith(servicePhotoPrefix);
}

String servicePhotoDataUri(Uint8List jpeg) {
  return '$servicePhotoPrefix${base64Encode(jpeg)}';
}

Uint8List? servicePhotoBytes(String? value) {
  if (!isUploadedServicePhoto(value)) return null;
  try {
    return base64Decode(value!.substring(servicePhotoPrefix.length));
  } catch (_) {
    return null;
  }
}

/// Center-crops to a square and stores a small JPEG so the shared record stays light.
Uint8List? compressServicePhoto(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > servicePhotoMaxSourceBytes) return null;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final square = img.copyResizeCropSquare(
    decoded,
    size: servicePhotoEdge,
    interpolation: img.Interpolation.linear,
  );
  var jpeg = Uint8List.fromList(img.encodeJpg(square, quality: 72));
  if (servicePhotoDataUri(jpeg).length > maxServicePhotoUriLength) {
    jpeg = Uint8List.fromList(img.encodeJpg(square, quality: 55));
  }
  if (servicePhotoDataUri(jpeg).length > maxServicePhotoUriLength) return null;
  return jpeg;
}

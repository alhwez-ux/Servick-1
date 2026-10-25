import 'external_url_stub.dart'
    if (dart.library.js_interop) 'external_url_web.dart'
    as impl;

final openedExternalUrls = <String>[];
var captureExternalUrls = false;

void openExternalUrl(String url) {
  if (captureExternalUrls) {
    openedExternalUrls.add(url);
    return;
  }
  impl.openExternalUrlImpl(url);
}

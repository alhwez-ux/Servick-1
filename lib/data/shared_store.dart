import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_snapshot.dart';

const sharedStoreUrl = String.fromEnvironment(
  'SERVICK_STORE',
  defaultValue: 'https://servick1.vercel.app/api/state',
);

const sharedCacheKey = 'servick.shared.v1';

abstract class SharedStore {
  Future<SharedSnapshot?> load();

  Future<void> save(SharedSnapshot snapshot);

  Future<SharedSnapshot?> readCache();
}

class MemorySharedStore implements SharedStore {
  SharedSnapshot? value;

  @override
  Future<SharedSnapshot?> load() async => value;

  @override
  Future<void> save(SharedSnapshot snapshot) async {
    value = snapshot;
  }

  @override
  Future<SharedSnapshot?> readCache() async => null;
}

class HttpSharedStore implements SharedStore {
  HttpSharedStore({http.Client? client, this.url = sharedStoreUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String url;

  @override
  Future<SharedSnapshot?> load() async {
    final response = await _client
        .get(
          Uri.parse('$url?t=${DateTime.now().millisecondsSinceEpoch}'),
          headers: const {
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
          },
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw SharedStoreException(response.statusCode);
    }
    return SharedSnapshot.tryParse(response.body);
  }

  @override
  Future<void> save(SharedSnapshot snapshot) async {
    final body = snapshot.encode();
    final response = await _client
        .put(
          Uri.parse(url),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SharedStoreException(response.statusCode);
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(sharedCacheKey, body);
    } catch (_) {}
  }

  @override
  Future<SharedSnapshot?> readCache() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(sharedCacheKey);
      if (raw == null || raw.isEmpty) return null;
      return SharedSnapshot.tryParse(raw);
    } catch (_) {
      return null;
    }
  }
}

class SharedStoreException implements Exception {
  SharedStoreException(this.statusCode);

  final int statusCode;
}

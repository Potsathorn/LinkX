import 'package:flutter/foundation.dart';

import '../../core/constants/app_config.dart';
import '../datasources/local_storage.dart';
import '../models/onelink_config.dart';

class OneLinkRepository extends ChangeNotifier {
  OneLinkRepository(this._storage);

  final LocalStorage _storage;

  List<GeneratedOneLink> loadAll() => _storage.readList<GeneratedOneLink>(
        AppConfig.kOneLinkCacheKey,
        GeneratedOneLink.fromJson,
      );

  GeneratedOneLink? find({required String env, required String deeplink}) {
    for (final GeneratedOneLink link in loadAll()) {
      if (link.matches(env, deeplink)) return link;
    }
    return null;
  }

  Future<GeneratedOneLink> save(GeneratedOneLink link) async {
    final List<GeneratedOneLink> cached = loadAll()
      ..removeWhere((GeneratedOneLink e) => e.matches(link.env, link.deeplink))
      ..insert(0, link);

    if (cached.length > AppConfig.oneLinkCacheLimit) {
      cached.removeRange(AppConfig.oneLinkCacheLimit, cached.length);
    }

    await _storage.writeList(
      AppConfig.kOneLinkCacheKey,
      cached,
      (GeneratedOneLink e) => e.toJson(),
    );
    notifyListeners();
    return link;
  }

  Future<void> clear() async {
    await _storage.remove(AppConfig.kOneLinkCacheKey);
    notifyListeners();
  }
}

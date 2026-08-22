import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._(this._prefs);

  final SharedPreferences _prefs;

  static LocalStorage? _instance;

  static Future<LocalStorage> getInstance() async {
    _instance ??= LocalStorage._(await SharedPreferences.getInstance());
    return _instance!;
  }

  @visibleForTesting
  static void resetForTesting() => _instance = null;

  List<T> readList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final String? raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((dynamic e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> writeList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T item) toJson,
  ) async {
    final String raw = jsonEncode(items.map(toJson).toList());
    await _prefs.setString(key, raw);
  }

  Future<void> remove(String key) => _prefs.remove(key);
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'enhanced_shared_preferences_platform_interface.dart';

/// Wraps NSUserDefaults (on iOS) and SharedPreferences (on Android), providing
/// a persistent store for simple data.
///
/// Data is persisted to disk asynchronously.
class EnhancedSharedPreferences {
  EnhancedSharedPreferences._(this._preferenceCache);

  static Completer<EnhancedSharedPreferences>? _completer;

  /// Currently loaded [SharedPreferences] file name
  static String? _fileName;

  static EnhancedSharedPreferencesStorePlatform get _store =>
      EnhancedSharedPreferencesStorePlatform.instance;

  /// Loads and parses the [EnhancedSharedPreferences] for this app from disk.
  ///
  /// Because this is reading from disk, it shouldn't be awaited in
  /// performance-sensitive blocks.
  static Future<EnhancedSharedPreferences> getInstance({String? fileName}) async {
    if (_fileName != fileName) {
      _fileName = fileName;
      // Reset completer to null to read a different SharedPreferences file.
      _completer = null;
    }

    if (_completer == null) {
      final Completer<EnhancedSharedPreferences> completer =
      Completer<EnhancedSharedPreferences>();
      try {
        final Map<String, Object> preferencesMap =
        await _getSharedPreferencesMap();
        completer.complete(EnhancedSharedPreferences._(preferencesMap));
      } on Exception catch (e) {
        // If there's an error, explicitly return the future with an error.
        // then set the completer to null so we can retry.
        completer.completeError(e);
        final Future<EnhancedSharedPreferences> sharedPrefsFuture = completer.future;
        _completer = null;
        return sharedPrefsFuture;
      }
      _completer = completer;
    }
    return _completer!.future;
  }

  /// The cache that holds all preferences.
  ///
  /// It is instantiated to the current state of the SharedPreferences or
  /// NSUserDefaults object and then kept in sync via setter methods in this
  /// class.
  ///
  /// It is NOT guaranteed that this cache and the device prefs will remain
  /// in sync since the setter method might fail for any reason.
  final Map<String, Object> _preferenceCache;

  /// Returns all keys in the persistent storage.
  Set<String> getKeys() => Set<String>.from(_preferenceCache.keys);

  /// Reads a value of any type from persistent storage.
  Object? get(String key) => _preferenceCache[key];

  /// Reads a value from persistent storage, return null if it's not existed or not an bool.
  bool? getBool(String key) {
    final value = _preferenceCache[key];
    return (value is bool) ? value : null;
  }

  /// Reads a value from persistent storage, return null if it's not existed or not an int.
  int? getInt(String key) {
    final value = _preferenceCache[key];
    return (value is int) ? value : null;
  }

  /// Reads a value from persistent storage, return null if it's not existed or not an double.
  double? getDouble(String key) {
    final value = _preferenceCache[key];
    return (value is double) ? value : null;
  }

  /// Reads a value from persistent storage, return null if it's not existed or not an String.
  String? getString(String key) {
    final value = _preferenceCache[key];
    return (value is String) ? value : null;
  }

  /// Returns true if persistent storage the contains the given [key].
  bool containsKey(String key) => _preferenceCache.containsKey(key);

  /// Reads a set of string values from persistent storage, return null if it's not existed or not a string set.
  List<String>? getStringList(String key) {
    List<dynamic>? list = _preferenceCache[key] as List<dynamic>?;
    if (list != null && list is! List<String>) {
      list = list.cast<String>().toList();
      _preferenceCache[key] = list;
    }
    // Make a copy of the list so that later mutations won't propagate
    return list?.toList() as List<String>?;
  }

  /// Saves a boolean [value] to persistent storage in the background.
  Future<bool> setBool(String key, bool value) => _setValue('Bool', key, value);

  /// Saves an integer [value] to persistent storage in the background.
  Future<bool> setInt(String key, int value) => _setValue('Int', key, value);

  /// Saves a double [value] to persistent storage in the background.
  ///
  /// Android doesn't support storing doubles, so it will be stored as a float.
  Future<bool> setDouble(String key, double value) =>
      _setValue('Double', key, value);

  /// Saves a string [value] to persistent storage in the background.
  ///
  /// Note: Due to limitations in Android's SharedPreferences,
  /// values cannot start with any one of the following:
  ///
  /// - 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu'
  /// - 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy'
  /// - 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu'
  Future<bool> setString(String key, String value) =>
      _setValue('String', key, value);

  /// Saves a list of strings [value] to persistent storage in the background.
  Future<bool> setStringList(String key, List<String> value) =>
      _setValue('StringList', key, value);

  /// Removes an entry from persistent storage.
  Future<bool> remove(String key) {
    _preferenceCache.remove(key);
    return _store.remove(key, fileName: _fileName);
  }

  Future<bool> _setValue(String valueType, String key, Object value) {
    ArgumentError.checkNotNull(value, 'value');
    if (value is List<String>) {
      // Make a copy of the list so that later mutations won't propagate
      _preferenceCache[key] = value.toList();
    } else {
      _preferenceCache[key] = value;
    }
    return _store.setValue(valueType, key, value, fileName: _fileName);
  }

  /// Completes with true once the user preferences for the app has been cleared.
  Future<bool> clear() {
    _preferenceCache.clear();
    return _store.clear();
  }

  /// Fetches the latest values from the host platform.
  ///
  /// Use this method to observe modifications that were made in native code
  /// (without using the plugin) while the app is running.
  Future<void> reload() async {
    final Map<String, Object> preferences =
    await EnhancedSharedPreferences._getSharedPreferencesMap();
    _preferenceCache.clear();
    _preferenceCache.addAll(preferences);
  }

  static Future<Map<String, Object>> _getSharedPreferencesMap() async {
    final Map<String, Object> fromSystem = await _store.getAll(fileName: _fileName);
    final Map<String, Object> preferencesMap = <String, Object>{};
    for (final String key in fromSystem.keys) {
      preferencesMap[key] = fromSystem[key]!;
    }
    return preferencesMap;
  }

  /// Initializes the shared preferences with mock values for testing.
  ///
  /// If the singleton instance has been initialized already, it is nullified.
  @visibleForTesting
  static void setMockInitialValues(Map<String, Object> values) {
    final Map<String, Object> newValues =
    values.map<String, Object>((String key, Object value) {
      return MapEntry<String, Object>(key, value);
    });
    EnhancedSharedPreferencesStorePlatform.instance =
        InMemoryEnhancedSharedPreferencesStore.withData(newValues);
    _completer = null;
  }
}

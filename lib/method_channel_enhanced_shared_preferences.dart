// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';

import 'enhanced_shared_preferences_platform_interface.dart';

const MethodChannel _kChannel =
    MethodChannel('plugins.lucian.com/enhanced_shared_preferences');

/// Wraps NSUserDefaults (on iOS) and EnhancedSharedPreferences (on Android), providing
/// a persistent store for simple data.
///
/// Data is persisted to disk asynchronously.
class MethodChannelEnhancedSharedPreferencesStore
    extends EnhancedSharedPreferencesStorePlatform {
  @override
  Future<bool> remove(String key, {String? fileName}) async {
    return (await _kChannel.invokeMethod<bool>(
      'remove',
      <String, dynamic>{'key': key, 'fileName': fileName},
    ))!;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value, {String? fileName}) async {
    return (await _kChannel.invokeMethod<bool>(
      'set$valueType',
      <String, dynamic>{'key': key, 'value': value, 'fileName': fileName},
    ))!;
  }

  @override
  Future<bool> clear({String? fileName}) async {
    return (await _kChannel.invokeMethod<bool>(
      'clear',
      <String, dynamic>{'fileName': fileName},
    ))!;
  }

  @override
  Future<Map<String, Object>> getAll({String? fileName}) async {
    final Map<String, Object>? preferences = await _kChannel.invokeMapMethod<String, Object>(
      'getAll',
      <String, dynamic>{'fileName': fileName},
    );

    if (preferences == null) {
      return <String, Object>{};
    }
    return preferences;
  }
}

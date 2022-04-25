package com.lucian.enhanced_shared_preferences;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** EnhancedSharedPreferencesPlugin */
public class EnhancedSharedPreferencesPlugin implements FlutterPlugin {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private static final String CHANNEL_NAME = "plugins.lucian.com/enhancedshared_preferences_android";
  private MethodCallHandlerImpl handler;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    handler = new MethodCallHandlerImpl(binding.getApplicationContext());
    channel.setMethodCallHandler(handler);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    handler.teardown();
    handler = null;
    channel.setMethodCallHandler(null);
    channel = null;
  }
}

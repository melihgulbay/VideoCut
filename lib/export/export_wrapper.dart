import 'package:ffi/ffi.dart';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import '../native/bindings.dart';
import '../native/video_engine_wrapper.dart';

class ExportSettingsData {
  final String outputPath;
  final int width;
  final int height;
  final int bitrate;
  final double frameRate;
  final String codec;
  final int audioBitrate;
  final int audioSampleRate;

  ExportSettingsData({
    required this.outputPath,
    this.width = 1920,
    this.height = 1080,
    this.bitrate = 5000000,
    this.frameRate = 30.0,
    this.codec = 'h264',
    this.audioBitrate = 192000,
    this.audioSampleRate = 48000,
  });
}

class VideoExporter {
  Pointer<Void>? _handle;
  bool _isExporting = false;

  VideoExporter() {
    if (isNativeAvailable && NativeBindings.exporterCreate != null) {
      _handle = NativeBindings.exporterCreate!();
    }
  }

  Future<bool> startExport(
    TimelineController timeline,
    ExportSettingsData settings,
  ) async {
    if (!isNativeAvailable || _handle == null) return false;
    if (_isExporting) return false;
    if (timeline.handle == null) return false;

    print('[Export] Starting export to: ${settings.outputPath}');
    print('[Export] Resolution: ${settings.width}x${settings.height}');
    print('[Export] Codec: ${settings.codec}');
    print('[Export] Bitrate: ${settings.bitrate}');
    print('[Export] Frame rate: ${settings.frameRate}');

    final settingsPtr = malloc<ExportSettings>();
    
    try {
      // Copy output_path
      for (int i = 0; i < 512; i++) {
        settingsPtr.ref.outputPath[i] = 0;
      }
      final pathBytes = Uint8List.fromList(settings.outputPath.codeUnits.map((e) => e & 0xFF).toList());
      for (int i = 0; i < pathBytes.length && i < 511; i++) {
        settingsPtr.ref.outputPath[i] = pathBytes[i];
      }

      // Copy format
      for (int i = 0; i < 16; i++) {
        settingsPtr.ref.format[i] = 0;
}
      final formatBytes = Uint8List.fromList('mp4'.codeUnits.map((e) => e & 0xFF).toList());
      for (int i = 0; i < formatBytes.length; i++) {
        settingsPtr.ref.format[i] = formatBytes[i];
    }

      // Copy codec
      for (int i = 0; i < 16; i++) {
        settingsPtr.ref.codec[i] = 0;
      }
    final codecBytes = Uint8List.fromList(settings.codec.codeUnits.map((e) => e & 0xFF).toList());
      for (int i = 0; i < codecBytes.length; i++) {
        settingsPtr.ref.codec[i] = codecBytes[i];
      }

      // Set other settings
   settingsPtr.ref.width = settings.width;
      settingsPtr.ref.height = settings.height;
      settingsPtr.ref.bitrate = settings.bitrate;
 settingsPtr.ref.fps = settings.frameRate.toInt();
 settingsPtr.ref.frameRate = settings.frameRate.toInt();

  print('[Export] Calling native exporter_start...');
final result = NativeBindings.exporterStart!(
  _handle!,
  timeline.handle!,
 settingsPtr,
      );

      print('[Export] Native result: $result');
      if (result == 0) {
 _isExporting = true;
return true;
  }
 return false;
    } finally {
      malloc.free(settingsPtr);
    }
  }

  double getProgress() {
    if (!isNativeAvailable || _handle == null) return 0.0;

    final progressPtr = malloc<Float>();
    try {
      final result = NativeBindings.exporterProgress!(_handle!, progressPtr);
      if (result == 0) {
   return progressPtr.value.toDouble();
      }
      return 0.0;
    } finally {
  malloc.free(progressPtr);
    }
  }

  bool cancel() {
    if (!isNativeAvailable || _handle == null) return false;

    final result = NativeBindings.exporterCancel!(_handle!);
    if (result == 0) {
_isExporting = false;
      return true;
    }
    return false;
  }

  bool get isExporting {
    if (!isNativeAvailable || _handle == null) return false;
    final result = NativeBindings.exporterIsExporting!(_handle!);
    return result != 0;
  }

  void dispose() {
    if (_handle != null && NativeBindings.exporterDestroy != null) {
  NativeBindings.exporterDestroy!(_handle!);
      _handle = null;
    }
  }
}

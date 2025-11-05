import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

// Load native library with error handling
DynamicLibrary? _tryLoadLibrary() {
  try {
  if (Platform.isWindows) {
      // Try multiple locations for the DLL
      final possiblePaths = [
        // In the same directory as executable (for release builds)
        'videocut_native.dll',
        // In the lib directory (for development)
        path.join(Directory.current.path, 'lib', 'videocut_native.dll'),
        // In the build output directory (for debug builds)
        path.join(Directory.current.path, 'build', 'windows', 'x64', 'runner', 'Release', 'videocut_native.dll'),
        path.join(Directory.current.path, 'build', 'windows', 'x64', 'runner', 'Debug', 'videocut_native.dll'),
        // In native build directory
        path.join(Directory.current.path, 'native', 'build', 'Release', 'videocut_native.dll'),
 ];
      
      for (final dllPath in possiblePaths) {
     try {
          final file = File(dllPath);
          if (file.existsSync()) {
            print('Found native library at: $dllPath');
            return DynamicLibrary.open(file.absolute.path);
       }
        } catch (e) {
          // Try next path
          continue;
      }
      }
  
      throw Exception('videocut_native.dll not found in any expected location');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libvideocut_native.dylib');
    } else {
      return DynamicLibrary.open('libvideocut_native.so');
    }
  } catch (e) {
    print('Warning: Could not load native library: $e');
    print('The app will run in demo mode without video processing capabilities.');
    print('Please ensure the native library is built by running build.bat');
 return null;
  }
}

final DynamicLibrary? nativeLib = _tryLoadLibrary();
final bool isNativeAvailable = nativeLib != null;

// Error codes
class ErrorCode {
  static const int success = 0;
  static const int errorInvalidFile = -1;
  static const int errorDecodeFailed = -2;
  static const int errorEncodeFailed = -3;
  static const int errorOutOfMemory = -4;
  static const int errorInvalidParameter = -5;
  static const int errorNotInitialized = -6;
}

// FFI Structs
final class VideoMetadata extends Struct {
  @Int64()
  external int durationMs;
  
  @Int32()
  external int width;
  
  @Int32()
  external int height;
  
  @Double()
  external double frameRate;
  
  @Int64()
  external int bitrate;
  
  @Array(32)
external Array<Uint8> codec;
  
  @Int32()
  external int audioChannels;
  
  @Int32()
  external int audioSampleRate;
}

final class ClipInfo extends Struct {
  @Int32()
  external int clipId;
  
  @Int32()  // Clip type (0 = video, 1 = audio-only)
  external int clipType;
  
  @Array(512)  // filepath field - CRITICAL!
  external Array<Uint8> filepath;
  
  @Int32()
  external int trackIndex;
  
  @Int64()
  external int startTimeMs;
  
  @Int64()
  external int endTimeMs;
  
  @Int64()
  external int durationMs;  // Added duration_ms field
  
  @Int64()
  external int trimStartMs;
  
  @Int64()
  external int trimEndMs;
  
  @Double()
  external double speed;
  
  @Float()
  external double volume;
  
  @Bool()
  external bool isMuted;
  
  @Float()
  external double scaleX;     // NEW: Horizontal scale
  
  @Float()
  external double scaleY;     // NEW: Vertical scale
  
  @Bool()
  external bool lockAspectRatio; // NEW: Lock aspect ratio
}

final class ExportSettings extends Struct {
  @Array(512)
  external Array<Uint8> outputPath;  // char output_path[512]
  
  @Int32()
  external int width;  // int width
  
  @Int32()
  external int height;  // int height
  
  @Int32()  // Fixed: was Int64, should be Int32
  external int bitrate;  // int bitrate
  
  @Int32()
  external int fps;  // int fps
  
  @Array(16)
  external Array<Uint8> format;  // char format[16]
  
  @Array(16)
  external Array<Uint8> codec;  // char codec[16]
  
  @Int32()
  external int frameRate;  // int frame_rate
}

final class FrameData extends Struct {
  external Pointer<Uint8> data;
  
  @Int32()
  external int width;
  
  @Int32()
  external int height;
  
  @Int64()
  external int timestampMs;
  
  @Int32()
  external int format;
}

final class AudioWaveform extends Struct {
  external Pointer<Float> samples;
  
  @Int32()
  external int sampleCount;
  
  @Int32()
  external int channels;
}

// NEW: Text layer struct
final class TextLayer extends Struct {
  @Int32()
  external int layerId;
  
  @Array(512)
  external Array<Uint8> text;
  
  @Int32()
  external int trackIndex;
  
  @Int64()
  external int startTimeMs;
  
  @Int64()
  external int endTimeMs;
  
  @Float()
  external double x;
  
  @Float()
  external double y;
  
  @Int32()
  external int fontSize;
  
  @Array(64)
  external Array<Uint8> fontFamily;
  
  @Int32()
  external int colorR;
  
  @Int32()
  external int colorG;
  
  @Int32()
  external int colorB;
  
  @Int32()
  external int colorA;
  
  @Int32()
  external int bgColorR;
  
  @Int32()
  external int bgColorG;
  
  @Int32()
  external int bgColorB;
  
  @Int32()
  external int bgColorA;
  
  @Float()
  external double rotation;
  
  @Float()
  external double scale;
  
  @Int32()
  external int alignment;
  
  @Bool()
  external bool bold;
  
  @Bool()
  external bool italic;
  
  @Bool()
  external bool underline;
  
  @Bool()
  external bool hasBackground;
}

// NEW: TrackInfo struct
final class TrackInfo extends Struct {
  @Int32()
  external int trackId;
  
  @Int32()
  external int trackType;
  
  @Array(64)
external Array<Uint8> trackName;
  
  @Int32()
  external int displayOrder;
  
  @Bool()
  external bool isLocked;
  
  @Bool()
  external bool isVisible;
  
  @Float()
  external double opacity;
}

// NEW: RenderSettings struct (shared render contract)
final class RenderSettings extends Struct {
  @Int32()
  external int width;

  @Int32()
  external int height;

  @Int32()
  external int supersample;

  @Float()
  external double dpiScale;

  // C++ bool is mapped to1 byte; store as int8
  @Int8()
  external int useGpu;
}

// Native function bindings
typedef VideocutInitializeNative = Void Function();
typedef VideocutInitialize = void Function();

typedef TimelineCreateNative = Pointer<Void> Function();
typedef TimelineCreate = Pointer<Void> Function();

typedef TimelineDestroyNative = Void Function(Pointer<Void> handle);
typedef TimelineDestroy = void Function(Pointer<Void> handle);

typedef TimelineAddClipNative = Int32 Function(
    Pointer<Void> handle, Pointer<Utf8> filepath, Int32 trackIndex, Int64 startTimeMs);
typedef TimelineAddClip = int Function(
    Pointer<Void> handle, Pointer<Utf8> filepath, int trackIndex, int startTimeMs);

typedef TimelineRemoveClipNative = Int32 Function(Pointer<Void> handle, Int32 clipId);
typedef TimelineRemoveClip = int Function(Pointer<Void> handle, int clipId);

typedef TimelineUpdateClipNative = Int32 Function(
  Pointer<Void> handle, Int32 clipId, Pointer<ClipInfo> info);
typedef TimelineUpdateClip = int Function(
  Pointer<Void> handle, int clipId, Pointer<ClipInfo> info);

typedef TimelineGetClipNative = Int32 Function(
    Pointer<Void> handle, Int32 clipId, Pointer<ClipInfo> info);
typedef TimelineGetClip = int Function(
    Pointer<Void> handle, int clipId, Pointer<ClipInfo> info);

typedef TimelineGetClipCountNative = Int32 Function(Pointer<Void> handle);
typedef TimelineGetClipCount = int Function(Pointer<Void> handle);

typedef TimelineGetAllClipsNative = Int32 Function(
    Pointer<Void> handle, Pointer<ClipInfo> clips, Int32 maxCount);
typedef TimelineGetAllClips = int Function(
    Pointer<Void> handle, Pointer<ClipInfo> clips, int maxCount);

typedef TimelineSplitClipNative = Int32 Function(
    Pointer<Void> handle, Int32 clipId, Int64 splitTimeMs, Pointer<Int32> newClipId);
typedef TimelineSplitClip = int Function(
    Pointer<Void> handle, int clipId, int splitTimeMs, Pointer<Int32> newClipId);

typedef TimelineTrimClipNative = Int32 Function(
    Pointer<Void> handle, Int32 clipId, Int64 trimStartMs, Int64 trimEndMs);
typedef TimelineTrimClip = int Function(
    Pointer<Void> handle, int clipId, int trimStartMs, int trimEndMs);

typedef TimelineSetClipSpeedNative = Int32 Function(
 Pointer<Void> handle, Int32 clipId, Double speed);
typedef TimelineSetClipSpeed = int Function(Pointer<Void> handle, int clipId, double speed);

typedef TimelineSetClipVolumeNative = Int32 Function(
    Pointer<Void> handle, Int32 clipId, Float volume);
typedef TimelineSetClipVolume = int Function(Pointer<Void> handle, int clipId, double volume);

typedef TimelineMuteClipNative = Int32 Function(
    Pointer<Void> handle, Int32 clipId, Int32 muted);
typedef TimelineMuteClip = int Function(Pointer<Void> handle, int clipId, int muted);

typedef TimelineRenderFrameNative = Int32 Function(
    Pointer<Void> handle, Int64 timestampMs, Pointer<FrameData> frame);
typedef TimelineRenderFrame = int Function(
    Pointer<Void> handle, int timestampMs, Pointer<FrameData> frame);

typedef TimelineReleaseFrameNative = Void Function(Pointer<FrameData> frame);
typedef TimelineReleaseFrame = void Function(Pointer<FrameData> frame);

typedef TimelineGetDurationNative = Int64 Function(Pointer<Void> handle);
typedef TimelineGetDuration = int Function(Pointer<Void> handle);

typedef TimelineUndoNative = Int32 Function(Pointer<Void> handle);
typedef TimelineUndo = int Function(Pointer<Void> handle);

typedef TimelineRedoNative = Int32 Function(Pointer<Void> handle);
typedef TimelineRedo = int Function(Pointer<Void> handle);

typedef TimelineCanUndoNative = Int32 Function(Pointer<Void> handle);
typedef TimelineCanUndo = int Function(Pointer<Void> handle);

typedef TimelineCanRedoNative = Int32 Function(Pointer<Void> handle);
typedef TimelineCanRedo = int Function(Pointer<Void> handle);

typedef VideoGetMetadataNative = Int32 Function(
    Pointer<Utf8> filepath, Pointer<VideoMetadata> metadata);
typedef VideoGetMetadata = int Function(
    Pointer<Utf8> filepath, Pointer<VideoMetadata> metadata);

typedef AudioGenerateWaveformNative = Int32 Function(
    Pointer<Utf8> filepath, Pointer<AudioWaveform> waveform, Int32 sampleCount);
typedef AudioGenerateWaveform = int Function(
    Pointer<Utf8> filepath, Pointer<AudioWaveform> waveform, int sampleCount);

typedef AudioReleaseWaveformNative = Void Function(Pointer<AudioWaveform> waveform);
typedef AudioReleaseWaveform = void Function(Pointer<AudioWaveform> waveform);

// NEW: Export functionality
typedef ExporterCreateNative = Pointer<Void> Function();
typedef ExporterCreate = Pointer<Void> Function();

typedef ExporterDestroyNative = Void Function(Pointer<Void> handle);
typedef ExporterDestroy = void Function(Pointer<Void> handle);

typedef ExporterStartNative = Int32 Function(
    Pointer<Void> exporterHandle, Pointer<Void> timelineHandle, Pointer<ExportSettings> settings);
typedef ExporterStart = int Function(
Pointer<Void> exporterHandle, Pointer<Void> timelineHandle, Pointer<ExportSettings> settings);

typedef ExporterGetProgressNative = Int32 Function(Pointer<Void> handle, Pointer<Float> progress);
typedef ExporterGetProgress = int Function(Pointer<Void> handle, Pointer<Float> progress);

typedef ExporterCancelNative = Int32 Function(Pointer<Void> handle);
typedef ExporterCancel = int Function(Pointer<Void> handle);

typedef ExporterIsExportingNative = Int32 Function(Pointer<Void> handle);
typedef ExporterIsExporting = int Function(Pointer<Void> handle);

// NEW: Audio-only file detection
typedef _audio_is_audio_only_native = Int32 Function(Pointer<Utf8> filepath);
typedef _audio_is_audio_only_dart = int Function(Pointer<Utf8> filepath);

final _audioIsAudioOnly = isNativeAvailable
  ? nativeLib!.lookup<NativeFunction<_audio_is_audio_only_native>>('audio_is_audio_only')
  .asFunction<_audio_is_audio_only_dart>()
    : null;

bool isAudioOnlyFile(String filepath) {
  if (!isNativeAvailable || _audioIsAudioOnly == null) return false;
  
  final pathPtr = filepath.toNativeUtf8();
  try {
   final result = _audioIsAudioOnly!(pathPtr);
 return result == 1;
  } finally {
    malloc.free(pathPtr);
  }
}

// NEW: Audio metadata
typedef _audio_get_metadata_native = Int32 Function(
    Pointer<Utf8> filepath, Pointer<Int64> duration, Pointer<Int32> channels, Pointer<Int32> sampleRate);
typedef _audio_get_metadata_dart = int Function(
  Pointer<Utf8> filepath, Pointer<Int64> duration, Pointer<Int32> channels, Pointer<Int32> sampleRate);

final _audioGetMetadata = isNativeAvailable
    ? nativeLib!.lookup<NativeFunction<_audio_get_metadata_native>>('audio_get_metadata')
        .asFunction<_audio_get_metadata_dart>()
    : null;

// NEW: Extract audio from video
typedef _video_extract_audio_native = Int32 Function(Pointer<Utf8> videoPath, Pointer<Utf8> outputMp3Path);
typedef _video_extract_audio_dart = int Function(Pointer<Utf8> videoPath, Pointer<Utf8> outputMp3Path);

final _videoExtractAudio = isNativeAvailable
    ? nativeLib!.lookup<NativeFunction<_video_extract_audio_native>>('video_extract_audio')
 .asFunction<_video_extract_audio_dart>()
    : null;

String? extractAudioFromVideo(String videoPath, String outputBasePath) {
  if (!isNativeAvailable || _videoExtractAudio == null) return null;
  
  // Try both AAC and MP3 output paths
  for (final ext in ['.aac', '.mp3']) {
    final outputPath = outputBasePath.replaceAll(RegExp(r'\.(mp3|aac)$'), ext);
    final videoPathPtr = videoPath.toNativeUtf8();
    final outputPathPtr = outputPath.toNativeUtf8();
    
    try {
   final result = _videoExtractAudio!(videoPathPtr, outputPathPtr);
      if (result == 0) {
        // Check if file was actually created
        if (File(outputPath).existsSync()) {
       return outputPath; // Return the actual path that was created
        }
      }
    } finally {
      malloc.free(videoPathPtr);
      malloc.free(outputPathPtr);
    }
  }
  
  return null; // Failed to extract
}

// Audio metadata class
class AudioMetadata {
  final int durationMs;
  final int channels;
  final int sampleRate;

  AudioMetadata({
    required this.durationMs,
    required this.channels,
    required this.sampleRate,
  });

  static AudioMetadata? getMetadata(String filepath) {
    if (!isNativeAvailable || _audioGetMetadata == null) return null;
    
    final pathPtr = filepath.toNativeUtf8();
    final durationPtr = malloc<Int64>();
    final channelsPtr = malloc<Int32>();
    final sampleRatePtr = malloc<Int32>();

    try {
      final result = _audioGetMetadata!(pathPtr, durationPtr, channelsPtr, sampleRatePtr);
    if (result == 0) {
     return AudioMetadata(
          durationMs: durationPtr.value,
          channels: channelsPtr.value,
          sampleRate: sampleRatePtr.value,
        );
      }
      return null;
    } finally {
      malloc.free(pathPtr);
      malloc.free(durationPtr);
      malloc.free(channelsPtr);
      malloc.free(sampleRatePtr);
    }
  }
}

// FFI typedef for extended render API
typedef TimelineRenderFrameExNative = Int32 Function(
 Pointer<Void> handle,
 Int64 timestampMs,
 Pointer<FrameData> frame,
 Pointer<RenderSettings> settings,
);
typedef TimelineRenderFrameEx = int Function(
 Pointer<Void> handle,
 int timestampMs,
 Pointer<FrameData> frame,
 Pointer<RenderSettings> settings,
);

// Bind native functions with null safety
class NativeBindings {
 static final videocutInitialize = isNativeAvailable
 ? nativeLib!.lookupFunction<VideocutInitializeNative, VideocutInitialize>('videocut_initialize')
 : null;

 static final timelineCreate = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineCreateNative, TimelineCreate>('timeline_create')
 : null;

 static final timelineDestroy = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineDestroyNative, TimelineDestroy>('timeline_destroy')
 : null;

 static final timelineAddClip = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineAddClipNative, TimelineAddClip>('timeline_add_clip')
 : null;

 static final timelineRemoveClip = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineRemoveClipNative, TimelineRemoveClip>('timeline_remove_clip')
 : null;

 static final timelineUpdateClip = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineUpdateClipNative, TimelineUpdateClip>('timeline_update_clip')
 : null;

 static final timelineGetClip = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineGetClipNative, TimelineGetClip>('timeline_get_clip')
 : null;

 static final timelineGetClipCount = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineGetClipCountNative, TimelineGetClipCount>('timeline_get_clip_count')
 : null;

 static final timelineGetAllClips = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineGetAllClipsNative, TimelineGetAllClips>('timeline_get_all_clips')
 : null;

 static final timelineSplitClip = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineSplitClipNative, TimelineSplitClip>('timeline_split_clip')
 : null;

 static final timelineTrimClip = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineTrimClipNative, TimelineTrimClip>('timeline_trim_clip')
 : null;

 static final timelineSetClipSpeed = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineSetClipSpeedNative, TimelineSetClipSpeed>('timeline_set_clip_speed')
 : null;

 static final timelineSetClipVolume = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineSetClipVolumeNative, TimelineSetClipVolume>('timeline_set_clip_volume')
 : null;

 static final timelineMuteClip = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineMuteClipNative, TimelineMuteClip>('timeline_mute_clip')
 : null;

 static final timelineRenderFrame = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineRenderFrameNative, TimelineRenderFrame>('timeline_render_frame')
 : null;

 static final timelineReleaseFrame = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineReleaseFrameNative, TimelineReleaseFrame>('timeline_release_frame')
 : null;

 static final timelineRenderFrameEx = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineRenderFrameExNative, TimelineRenderFrameEx>('timeline_render_frame_ex')
 : null;

 static final timelineGetDuration = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineGetDurationNative, TimelineGetDuration>('timeline_get_duration')
 : null;

 static final timelineUndo = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineUndoNative, TimelineUndo>('timeline_undo')
 : null;

 static final timelineRedo = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineRedoNative, TimelineRedo>('timeline_redo')
 : null;

 static final timelineCanUndo = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineCanUndoNative, TimelineCanUndo>('timeline_can_undo')
 : null;

 static final timelineCanRedo = isNativeAvailable
 ? nativeLib!.lookupFunction<TimelineCanRedoNative, TimelineCanRedo>('timeline_can_redo')
 : null;

 static final timelinePushState = isNativeAvailable
     ? nativeLib!.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('timeline_push_state')
     : null;
 
 // NEW: Clear undo/redo history
 static final timelineClearHistory = isNativeAvailable
 ? nativeLib!.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('timeline_clear_history')
     : null;

 static final videoMetadata = isNativeAvailable
 ? nativeLib!.lookupFunction<VideoGetMetadataNative, VideoGetMetadata>('video_get_metadata')
 : null;

 static final audioWaveform = isNativeAvailable
 ? nativeLib!.lookupFunction<AudioGenerateWaveformNative, AudioGenerateWaveform>('audio_generate_waveform')
 : null;

 static final audioReleaseWaveform = isNativeAvailable
 ? nativeLib!.lookupFunction<AudioReleaseWaveformNative, AudioReleaseWaveform>('audio_release_waveform')
 : null;

 static final exporterCreate = isNativeAvailable
 ? nativeLib!.lookupFunction<ExporterCreateNative, ExporterCreate>('exporter_create')
 : null;

 static final exporterDestroy = isNativeAvailable
 ? nativeLib!.lookupFunction<ExporterDestroyNative, ExporterDestroy>('exporter_destroy')
 : null;

 static final exporterStart = isNativeAvailable
 ? nativeLib!.lookupFunction<ExporterStartNative, ExporterStart>('exporter_start')
 : null;

 static final exporterProgress = isNativeAvailable
 ? nativeLib!.lookupFunction<ExporterGetProgressNative, ExporterGetProgress>('exporter_get_progress')
 : null;

 static final exporterCancel = isNativeAvailable
 ? nativeLib!.lookupFunction<ExporterCancelNative, ExporterCancel>('exporter_cancel')
 : null;

 static final exporterIsExporting = isNativeAvailable
 ? nativeLib!.lookupFunction<ExporterIsExportingNative, ExporterIsExporting>('exporter_is_exporting')
 : null;

 static final timelineAddTextLayer = isNativeAvailable
 ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>, Pointer<TextLayer>), int Function(Pointer<Void>, Pointer<TextLayer>)>('timeline_add_text_layer')
 : null;

 static final timelineRemoveTextLayer = isNativeAvailable
 ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>, Int32), int Function(Pointer<Void>, int)>('timeline_remove_text_layer')
 : null;

 static final timelineUpdateTextLayer = isNativeAvailable
 ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>, Int32, Pointer<TextLayer>), int Function(Pointer<Void>, int, Pointer<TextLayer>)>('timeline_update_text_layer')
 : null;

 static final timelineGetTextLayerCount = isNativeAvailable
 ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>('timeline_get_text_layer_count')
 : null;

 static final timelineGetAllTextLayers = isNativeAvailable
 ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>, Pointer<TextLayer>, Int32), int Function(Pointer<Void>, Pointer<TextLayer>, int)>('timeline_get_all_text_layers')
 : null;

 // Track management
 static final timelineAddTrack = isNativeAvailable
     ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>, Int32, Pointer<Utf8>), int Function(Pointer<Void>, int, Pointer<Utf8>)>('timeline_add_track')
     : null;

 static final timelineRemoveTrack = isNativeAvailable
     ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>, Int32), int Function(Pointer<Void>, int)>('timeline_remove_track')
     : null;

 static final timelineSwapTracks = isNativeAvailable
     ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>, Int32, Int32), int Function(Pointer<Void>, int, int)>('timeline_swap_tracks')
     : null;

 static final timelineGetTrackInfo = isNativeAvailable
     ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>, Int32, Pointer<TrackInfo>), int Function(Pointer<Void>, int, Pointer<TrackInfo>)>('timeline_get_track_info')
     : null;

 static final timelineGetTrackCount = isNativeAvailable
     ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>('timeline_get_track_count')
  : null;

 static final timelineGetAllTracks = isNativeAvailable
     ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>, Pointer<TrackInfo>, Int32), int Function(Pointer<Void>, Pointer<TrackInfo>, int)>('timeline_get_all_tracks')
 : null;
 
 // NEW: Scale operations
 static final timelineSetClipScale = isNativeAvailable
     ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>, Int32, Float, Float), int Function(Pointer<Void>, int, double, double)>('timeline_set_clip_scale')
     : null;
 
 static final timelineSetClipAspectLock = isNativeAvailable
   ? nativeLib!.lookupFunction<Int32 Function(Pointer<Void>, Int32, Int32), int Function(Pointer<Void>, int, int)>('timeline_set_clip_aspect_lock')
     : null;
}

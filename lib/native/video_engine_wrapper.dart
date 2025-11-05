import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';  // For Color
import '../models/text_layer_data.dart';  // For TextLayerData
import 'bindings.dart';

// NEW: Clip type enum
enum ClipType {
  video,      // Video with optional audio
  audioOnly,  // Audio-only clip (MP3, WAV, etc.)
}

class VideoCutEngine {
  static bool _initialized = false;

  static void initialize() {
    if (!_initialized) {
      if (isNativeAvailable && NativeBindings.videocutInitialize != null) {
        NativeBindings.videocutInitialize!();
      }
      _initialized = true;
    }
  }
}

class TimelineController {
  Pointer<Void>? _handle;
  bool _disposed = false;
  final bool _mockMode;

  TimelineController() : _mockMode = !isNativeAvailable {
    VideoCutEngine.initialize();
    if (!_mockMode && NativeBindings.timelineCreate != null) {
      _handle = NativeBindings.timelineCreate!();
    }
  }

  bool get isValid => !_disposed && (_mockMode || _handle != nullptr);

  int addClip(String filepath, {int trackIndex = 0, int startTimeMs = 0}) {
    if (!isValid) return -1;
    if (_mockMode) {
      print('Mock mode: Would add clip $filepath at track $trackIndex, time $startTimeMs');
      return 1;
    }
    
    final pathPtr = filepath.toNativeUtf8();
    try {
      return NativeBindings.timelineAddClip!(_handle!, pathPtr, trackIndex, startTimeMs);
    } finally {
      malloc.free(pathPtr);
    }
  }

  bool removeClip(int clipId) {
    if (!isValid) return false;
    if (_mockMode) {
      print('Mock mode: Would remove clip $clipId');
      return true;
    }
    return NativeBindings.timelineRemoveClip!(_handle!, clipId) == ErrorCode.success;
  }

  ClipData? getClip(int clipId) {
    if (!isValid) return null;
    if (_mockMode) {
      return ClipData(
        clipId: clipId,
        clipType: ClipType.video,
        startTimeMs: 0,
        endTimeMs: 5000,
        trimStartMs: 0,
        trimEndMs: 5000,
      );
    }
    
    final infoPtr = malloc<ClipInfo>();
    try {
      if (NativeBindings.timelineGetClip!(_handle!, clipId, infoPtr) == ErrorCode.success) {
        return ClipData.fromNative(infoPtr.ref);
   }
      return null;
    } finally {
      malloc.free(infoPtr);
    }
  }

  List<ClipData> getAllClips() {
    if (!isValid) return [];
    if (_mockMode) return [];
    
    final count = NativeBindings.timelineGetClipCount!(_handle!);
    if (count == 0) return [];

    final clipsPtr = malloc<ClipInfo>(count);
    try {
      NativeBindings.timelineGetAllClips!(_handle!, clipsPtr, count);
      return List.generate(
count,
    (i) => ClipData.fromNative(clipsPtr.elementAt(i).ref),
      );
    } finally {
      malloc.free(clipsPtr);
    }
  }

  bool updateClip(int clipId, ClipData data) {
    if (!isValid) return false;
    if (_mockMode) {
      print('Mock mode: Would update clip $clipId');
      return true;
    }
    
    final infoPtr = malloc<ClipInfo>();
    try {
      data.writeToNative(infoPtr.ref);
   return NativeBindings.timelineUpdateClip!(_handle!, clipId, infoPtr) == ErrorCode.success;
    } finally {
   malloc.free(infoPtr);
    }
  }

  int? splitClip(int clipId, int splitTimeMs) {
    if (!isValid) return null;
    if (_mockMode) {
    print('Mock mode: Would split clip $clipId at $splitTimeMs');
      return 2;
    }
    
    final newIdPtr = malloc<Int32>();
    try {
      if (NativeBindings.timelineSplitClip!(_handle!, clipId, splitTimeMs, newIdPtr) ==
      ErrorCode.success) {
     return newIdPtr.value;
  }
      return null;
    } finally {
      malloc.free(newIdPtr);
    }
  }

  bool trimClip(int clipId, int trimStartMs, int trimEndMs) {
    if (!isValid) return false;
    if (_mockMode) {
      print('Mock mode: Would trim clip $clipId from $trimStartMs to $trimEndMs');
      return true;
    }
    return NativeBindings.timelineTrimClip!(_handle!, clipId, trimStartMs, trimEndMs) ==
      ErrorCode.success;
  }

  bool setClipSpeed(int clipId, double speed) {
    if (!isValid) return false;
    if (_mockMode) {
    print('Mock mode: Would set clip $clipId speed to $speed');
      return true;
    }
    return NativeBindings.timelineSetClipSpeed!(_handle!, clipId, speed) == ErrorCode.success;
  }

  bool setClipVolume(int clipId, double volume) {
if (!isValid) return false;
  if (_mockMode) {
    print('Mock mode: Would set clip $clipId volume to $volume');
      return true;
    }
    return NativeBindings.timelineSetClipVolume!(_handle!, clipId, volume) == ErrorCode.success;
  }

  bool muteClip(int clipId, bool muted) {
    if (!isValid) return false;
    if (_mockMode) {
      print('Mock mode: Would ${muted ? "mute" : "unmute"} clip $clipId');
      return true;
    }
    return NativeBindings.timelineMuteClip!(_handle!, clipId, muted ? 1 : 0) == ErrorCode.success;
  }

  bool setClipScale(int clipId, double scaleX, double scaleY) {
    if (!isValid) return false;
    if (_mockMode) {
      print('Mock mode: Would set clip $clipId scale to ($scaleX, $scaleY)');
      return true;
    }
    return NativeBindings.timelineSetClipScale!(_handle!, clipId, scaleX, scaleY) == ErrorCode.success;
  }

  bool setClipAspectLock(int clipId, bool locked) {
    if (!isValid) return false;
    if (_mockMode) {
      print('Mock mode: Would ${locked ? "lock" : "unlock"} aspect ratio for clip $clipId');
      return true;
    }
  return NativeBindings.timelineSetClipAspectLock!(_handle!, clipId, locked ? 1 : 0) == ErrorCode.success;
  }

  Uint8List? renderFrame(int timestampMs) {
    if (!isValid) return null;
    if (_mockMode) return null;
    
    final framePtr = malloc<FrameData>();
    try {
      if (NativeBindings.timelineRenderFrame!(_handle!, timestampMs, framePtr) ==
 ErrorCode.success) {
        final frame = framePtr.ref;
        final size = frame.width * frame.height * 4;
        final data = Uint8List.fromList(frame.data.asTypedList(size));
 NativeBindings.timelineReleaseFrame!(framePtr);
        return data;
      }
      return null;
  } finally {
      malloc.free(framePtr);
    }
  }

  // Add HQ render method using extended render API
 Uint8List? renderFrameEx(int timestampMs, {int width =1280, int height =720, int supersample =1, double dpiScale =1.0, bool useGpu = false}) {
 if (!isValid) return null;
 if (_mockMode) return null;

 final framePtr = calloc<FrameData>();
 final settingsPtr = calloc<RenderSettings>();
 try {
 settingsPtr.ref.width = width;
 settingsPtr.ref.height = height;
 settingsPtr.ref.supersample = supersample;
 settingsPtr.ref.dpiScale = dpiScale;
 settingsPtr.ref.useGpu = useGpu ?1 :0;

 final int res = NativeBindings.timelineRenderFrameEx != null
 ? NativeBindings.timelineRenderFrameEx!(_handle!, timestampMs, framePtr, settingsPtr)
 : (NativeBindings.timelineRenderFrame != null ? NativeBindings.timelineRenderFrame!(_handle!, timestampMs, framePtr) : -1);

 if (res == ErrorCode.success) {
 final frame = framePtr.ref;
 final size = frame.width * frame.height *4;
 final data = Uint8List.fromList(frame.data.asTypedList(size));
 if (NativeBindings.timelineReleaseFrame != null) {
 NativeBindings.timelineReleaseFrame!(framePtr);
 }
 return data;
 }
 return null;
 } finally {
 calloc.free(framePtr);
 calloc.free(settingsPtr);
 }
 }

 // Convenience: request preview rendered at export settings
 Uint8List? renderPreviewAtExportSize(int timestampMs, ExportSettings exportSettings) {
 return renderFrameEx(timestampMs, width: exportSettings.width, height: exportSettings.height, supersample:2);
 }
  int getDuration() {
    if (!isValid) return 0;
    if (_mockMode) return 60000;
    return NativeBindings.timelineGetDuration!(_handle!);
  }

  bool canUndo() {
    if (!isValid) return false;
    if (_mockMode) return false;
    return NativeBindings.timelineCanUndo!(_handle!) != 0;
  }

  bool canRedo() {
    if (!isValid) return false;
    if (_mockMode) return false;
    return NativeBindings.timelineCanRedo!(_handle!) != 0;
}

  bool undo() {
    if (!isValid) return false;
    if (_mockMode) {
    print('Mock mode: Would undo');
      return true;
    }
    return NativeBindings.timelineUndo!(_handle!) == ErrorCode.success;
  }

  bool redo() {
    if (!isValid) return false;
    if (_mockMode) {
      print('Mock mode: Would redo');
      return true;
    }
    return NativeBindings.timelineRedo!(_handle!) == ErrorCode.success;
  }
  
  void pushState() {
    if (!isValid) return;
    if (_mockMode) {
      print('Mock mode: Would push undo state');
      return;
    }
    NativeBindings.timelinePushState!(_handle!);
  }

  void clearHistory() {
    if (!isValid) return;
    if (_mockMode) {
      print('Mock mode: Would clear undo/redo history');
      return;
    }
    NativeBindings.timelineClearHistory!(_handle!);
  }

  // NEW: Text layer methods
  int addTextLayer(TextLayerData layer) {
    if (!isValid) return -1;
    if (_mockMode) {
      print('Mock mode: Would add text layer "${layer.text}"');
      return layer.layerId;
    }
    
    final textLayerPtr = malloc<TextLayer>();
    try {
      _writeTextLayerToNative(layer, textLayerPtr.ref);
      final result = NativeBindings.timelineAddTextLayer!(_handle!, textLayerPtr);
      return result >= 0 ? result : -1;
    } finally {
      malloc.free(textLayerPtr);
    }
  }

  bool removeTextLayer(int layerId) {
    if (!isValid) return false;
    if (_mockMode) {
      print('Mock mode: Would remove text layer $layerId');
      return true;
    }
    return NativeBindings.timelineRemoveTextLayer!(_handle!, layerId) == ErrorCode.success;
  }

  bool updateTextLayer(int layerId, TextLayerData layer) {
    if (!isValid) return false;
    if (_mockMode) {
      print('Mock mode: Would update text layer $layerId');
      return true;
    }
    
    final textLayerPtr = malloc<TextLayer>();
    try {
      _writeTextLayerToNative(layer, textLayerPtr.ref);
      return NativeBindings.timelineUpdateTextLayer!(_handle!, layerId, textLayerPtr) == ErrorCode.success;
    } finally {
      malloc.free(textLayerPtr);
    }
  }

  int getTextLayerCount() {
    if (!isValid) return 0;
    if (_mockMode) return 0;
    return NativeBindings.timelineGetTextLayerCount!(_handle!);
  }

  List<TextLayerData> getAllTextLayers() {
    if (!isValid) return [];
    if (_mockMode) return [];
    
    final count = getTextLayerCount();
    if (count ==0) return [];

    final layersPtr = malloc<TextLayer>(count);
    try {
      NativeBindings.timelineGetAllTextLayers!(_handle!, layersPtr, count);
      return List.generate(
 count,
 (i) => _readTextLayerFromNative(layersPtr.elementAt(i).ref),
      );
    } finally {
      malloc.free(layersPtr);
    }
  }

  void _writeTextLayerToNative(TextLayerData dartLayer, TextLayer nativeLayer) {
    nativeLayer.layerId = dartLayer.layerId;
    
    // Copy text
    final textBytes = dartLayer.text.codeUnits;
    for (int i = 0; i < textBytes.length && i < 511; i++) {
      nativeLayer.text[i] = textBytes[i];
    }
    // Null-terminate the string
    nativeLayer.text[textBytes.length] = 0;
    
    nativeLayer.trackIndex = dartLayer.trackIndex;
    nativeLayer.startTimeMs = dartLayer.startTimeMs;
    nativeLayer.endTimeMs = dartLayer.endTimeMs;
    nativeLayer.x = dartLayer.x;
    nativeLayer.y = dartLayer.y;
    nativeLayer.fontSize = dartLayer.fontSize;
    
    // Copy font family
    final fontBytes = dartLayer.fontFamily.codeUnits;
    for (int i = 0; i < fontBytes.length && i < 63; i++) {
      nativeLayer.fontFamily[i] = fontBytes[i];
    }
    // Null-terminate font family
    nativeLayer.fontFamily[fontBytes.length] = 0;
    
    nativeLayer.colorR = dartLayer.textColor.red;
    nativeLayer.colorG = dartLayer.textColor.green;
    nativeLayer.colorB = dartLayer.textColor.blue;
    nativeLayer.colorA = dartLayer.textColor.alpha.clamp(128, 255); // Ensure text has reasonable opacity
    
    if (dartLayer.backgroundColor != null) {
      nativeLayer.bgColorR = dartLayer.backgroundColor!.red;
      nativeLayer.bgColorG = dartLayer.backgroundColor!.green;
      nativeLayer.bgColorB = dartLayer.backgroundColor!.blue;
      nativeLayer.bgColorA = dartLayer.backgroundColor!.alpha;
      nativeLayer.hasBackground = true;
    } else {
      nativeLayer.bgColorR = 0;
      nativeLayer.bgColorG = 0;
      nativeLayer.bgColorB = 0;
      nativeLayer.bgColorA = 0;
      nativeLayer.hasBackground = false;
    }
    
    nativeLayer.rotation = dartLayer.rotation;
    nativeLayer.scale = dartLayer.scale;
    nativeLayer.alignment = dartLayer.alignment.index;
    nativeLayer.bold = dartLayer.bold;
    nativeLayer.italic = dartLayer.italic;
    nativeLayer.underline = dartLayer.underline;
  }

  TextLayerData _readTextLayerFromNative(TextLayer nativeLayer) {
    // Read text
    final textBytes = <int>[];
    for (int i = 0; i < 512; i++) {
      final byte = nativeLayer.text[i];
      if (byte == 0) break;
      textBytes.add(byte);
    }
    final text = String.fromCharCodes(textBytes);
    
    // Read font family
    final fontBytes = <int>[];
    for (int i = 0; i < 64; i++) {
      final byte = nativeLayer.fontFamily[i];
      if (byte == 0) break;
      fontBytes.add(byte);
    }
    final fontFamily = String.fromCharCodes(fontBytes);
    
    return TextLayerData(
      layerId: nativeLayer.layerId,
      text: text,
      trackIndex: nativeLayer.trackIndex,
      startTimeMs: nativeLayer.startTimeMs,
      endTimeMs: nativeLayer.endTimeMs,
      x: nativeLayer.x,
      y: nativeLayer.y,
      fontSize: nativeLayer.fontSize,
      fontFamily: fontFamily,
      textColor: Color.fromARGB(
        nativeLayer.colorA,
        nativeLayer.colorR,
        nativeLayer.colorG,
        nativeLayer.colorB,
      ),
      backgroundColor: nativeLayer.hasBackground
          ? Color.fromARGB(
              nativeLayer.bgColorA,
              nativeLayer.bgColorR,
              nativeLayer.bgColorG,
              nativeLayer.bgColorB,
            )
          : Colors.transparent,
      rotation: nativeLayer.rotation,
      scale: nativeLayer.scale,
      alignment: TextAlignmentType.values[nativeLayer.alignment],
      bold: nativeLayer.bold,
      italic: nativeLayer.italic,
      underline: nativeLayer.underline,
    );
  }

  void dispose() {
    if (!_disposed && !_mockMode && _handle != nullptr && NativeBindings.timelineDestroy != null) {
      NativeBindings.timelineDestroy!(_handle!);
      _disposed = true;
    }
  }

  // Expose handle for export
  Pointer<Void>? get handle => _handle;

  // NEW: Text layer synchronization
  void syncTextLayers(List<dynamic> textLayers) {
if (!isValid || _mockMode || textLayers.isEmpty) return;
    
 debugPrint('[Timeline] Syncing ${textLayers.length} text layers to native');
    
    // TODO: Complete text layer sync when bindings are fixed
    debugPrint('[Timeline] Text layer sync temporarily disabled - needs binding fixes');
    
    /* Temporarily commented until bindings are fixed
for (var layer in textLayers) {
   final textLayerPtr = malloc<TextLayer>();
      try {
        // Convert Dart TextLayerData to C++ TextLayer struct
   _writeTextLayerToNative(layer, textLayerPtr.ref);
   
      // Add to native timeline
        final result = NativeBindings.timelineAddTextLayer!(_handle!, textLayerPtr);
        if (result >= 0) {
       debugPrint('[Timeline] Added text layer ${layer.layerId}: "${layer.text}"');
        }
    } finally {
        malloc.free(textLayerPtr);
 }
    }
    */
  }

  // NEW: Track management methods
  int addTrack(TrackType trackType, {String? name}) {
    if (!isValid) return -1;
    if (_mockMode) {
 print('Mock mode: Would add track of type $trackType');
      return 1;
    }
    
    final namePtr = name != null ? name.toNativeUtf8() : nullptr;
    try {
      return NativeBindings.timelineAddTrack!(_handle!, trackType.index, namePtr);
    } finally {
      if (namePtr != nullptr) malloc.free(namePtr);
    }
  }

  bool removeTrack(int trackId) {
    if (!isValid) return false;
    if (_mockMode) {
      print('Mock mode: Would remove track $trackId');
      return true;
    }
    return NativeBindings.timelineRemoveTrack!(_handle!, trackId) == ErrorCode.success;
  }

  bool swapTracks(int trackA, int trackB) {
    if (!isValid) return false;
    if (_mockMode) {
      print('Mock mode: Would swap tracks $trackA and $trackB');
      return true;
    }
    return NativeBindings.timelineSwapTracks!(_handle!, trackA, trackB) == ErrorCode.success;
  }

  TrackData? getTrack(int trackId) {
    if (!isValid) return null;
    if (_mockMode) {
      return TrackData(
        trackId: trackId,
        trackType: TrackType.video,
        trackName: 'Mock Track $trackId',
        displayOrder: trackId,
        isLocked: false,
  isVisible: true,
        opacity: 1.0,
      );
    }
    
    final trackInfoPtr = malloc<TrackInfo>();
    try {
      if (NativeBindings.timelineGetTrackInfo!(_handle!, trackId, trackInfoPtr) == ErrorCode.success) {
        return TrackData.fromNative(trackInfoPtr.ref);
   }
      return null;
 } finally {
  malloc.free(trackInfoPtr);
    }
  }

  int getTrackCount() {
 if (!isValid) return 0;
    if (_mockMode) return 3;
    return NativeBindings.timelineGetTrackCount!(_handle!);
  }

  List<TrackData> getAllTracks() {
if (!isValid) return [];
    if (_mockMode) return [];
  
    final count = getTrackCount();
    if (count == 0) return [];

    final tracksPtr = malloc<TrackInfo>(count);
    try {
  NativeBindings.timelineGetAllTracks!(_handle!, tracksPtr, count);
    return List.generate(
        count,
      (i) => TrackData.fromNative(tracksPtr.elementAt(i).ref),
  );
    } finally {
    malloc.free(tracksPtr);
 }
  }
}

// NEW: Track type enum
enum TrackType {
  video,// Can contain video clips
  audio,    // Can contain audio clips only
  text,   // Can contain text layers only
  overlay,  // Video with alpha channel support
}

// NEW: Track data class
class TrackData {
  final int trackId;
  final TrackType trackType;
  final String trackName;
  final int displayOrder;
  final bool isLocked;
  final bool isVisible;
  final double opacity;

  TrackData({
    required this.trackId,
    required this.trackType,
  required this.trackName,
    required this.displayOrder,
    required this.isLocked,
    required this.isVisible,
    required this.opacity,
  });

  factory TrackData.fromNative(TrackInfo native) {
    // Read track name
    final nameBytes = <int>[];
    for (int i = 0; i < 64; i++) {
final byte = native.trackName[i];
      if (byte == 0) break;
      nameBytes.add(byte);
    }
    final trackName = String.fromCharCodes(nameBytes);
    
    return TrackData(
      trackId: native.trackId,
      trackType: TrackType.values[native.trackType],
      trackName: trackName,
      displayOrder: native.displayOrder,
      isLocked: native.isLocked,
      isVisible: native.isVisible,
      opacity: native.opacity,
  );
  }

  TrackData copyWith({
    String? trackName,
    int? displayOrder,
    bool? isLocked,
    bool? isVisible,
    double? opacity,
  }) {
    return TrackData(
      trackId: trackId,
      trackType: trackType,
   trackName: trackName ?? this.trackName,
      displayOrder: displayOrder ?? this.displayOrder,
      isLocked: isLocked ?? this.isLocked,
   isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
    );
  }
}

class ClipData {
  final int clipId;
  final ClipType clipType;  // NEW: Video or audio-only
  int startTimeMs;
  int endTimeMs;
  int trimStartMs;
  int trimEndMs;
  double speed;
  int trackIndex;
  double scaleX;    // NEW: Horizontal scale (1.0 = 100%)
  double scaleY;      // NEW: Vertical scale (1.0 = 100%)
  bool lockAspectRatio;      // NEW: Lock aspect ratio when scaling

  ClipData({
    required this.clipId,
    this.clipType = ClipType.video,  // NEW: Default to video
    required this.startTimeMs,
    required this.endTimeMs,
    required this.trimStartMs,
    required this.trimEndMs,
    this.speed = 1.0,
    this.trackIndex = 0,
    this.scaleX = 1.0,  // NEW: Default 100%
    this.scaleY = 1.0,         // NEW: Default 100%
    this.lockAspectRatio = true, // NEW: Default locked
  });

  factory ClipData.fromNative(ClipInfo native) {
    return ClipData(
      clipId: native.clipId,
      clipType: native.clipType == 0 ? ClipType.video : ClipType.audioOnly,  // NEW
      startTimeMs: native.startTimeMs,
 endTimeMs: native.endTimeMs,
    trimStartMs: native.trimStartMs,
 trimEndMs: native.endTimeMs,
   speed: native.speed,
      trackIndex: native.trackIndex,
      scaleX: native.scaleX,        // NEW
      scaleY: native.scaleY,        // NEW
      lockAspectRatio: native.lockAspectRatio, // NEW
    );
  }

  void writeToNative(ClipInfo native) {
native.clipId = clipId;
    native.clipType = clipType == ClipType.video ? 0 : 1;  // NEW
    native.startTimeMs = startTimeMs;
    native.endTimeMs = endTimeMs;
    native.trimStartMs = trimStartMs;
    native.trimEndMs = trimEndMs;
    native.speed = speed;
    native.volume = 1.0;
    native.isMuted = false;
    native.trackIndex = trackIndex;
    native.scaleX = scaleX; // NEW
    native.scaleY = scaleY;    // NEW
    native.lockAspectRatio = lockAspectRatio; // NEW
  }

  ClipData copyWith({
    ClipType? clipType,  // NEW
    int? startTimeMs,
    int? endTimeMs,
    int? trimStartMs,
    int? trimEndMs,
    double? speed,
    int? trackIndex,
    double? scaleX,     // NEW
    double? scaleY,     // NEW
    bool? lockAspectRatio,       // NEW
  }) {
    return ClipData(
      clipId: clipId,
  clipType: clipType ?? this.clipType,  // NEW
      startTimeMs: startTimeMs ?? this.startTimeMs,
      endTimeMs: endTimeMs ?? this.endTimeMs,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      speed: speed ?? this.speed,
trackIndex: trackIndex ?? this.trackIndex,
      scaleX: scaleX ?? this.scaleX,    // NEW
      scaleY: scaleY ?? this.scaleY,         // NEW
      lockAspectRatio: lockAspectRatio ?? this.lockAspectRatio, // NEW
    );
  }

  int get durationMs => endTimeMs - startTimeMs;
  
  // NEW: Check if this is an audio-only clip
  bool get isAudioOnly => clipType == ClipType.audioOnly;
}

class VideoMetadataData {
  final int durationMs;
  final int width;
  final int height;
  final double frameRate;
  final int bitrate;
  final String codec;
  final int audioChannels;
  final int audioSampleRate;

  VideoMetadataData({
    required this.durationMs,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.bitrate,
    required this.codec,
    required this.audioChannels,
    required this.audioSampleRate,
  });

  static VideoMetadataData? getMetadata(String filepath) {
    if (!isNativeAvailable) return null;

    final pathPtr = filepath.toNativeUtf8();
    final metadataPtr = calloc<VideoMetadata>();

    try {
final result = NativeBindings.videoMetadata!(pathPtr, metadataPtr);
      if (result == 0) {
        final metadata = metadataPtr.ref;
        
  final codecBytes = <int>[];
      for (int i = 0; i < 32; i++) {
          final byte = metadata.codec[i];
      if (byte == 0) break;
    codecBytes.add(byte);
        }
    final codecName = String.fromCharCodes(codecBytes);

        return VideoMetadataData(
durationMs: metadata.durationMs,
     width: metadata.width,
          height: metadata.height,
          frameRate: metadata.frameRate,
       bitrate: metadata.bitrate,
        codec: codecName,
   audioChannels: metadata.audioChannels,
audioSampleRate: metadata.audioSampleRate,
        );
      }
    } finally {
      calloc.free(pathPtr);
      calloc.free(metadataPtr);
    }

    return null;
  }

  static List<double>? generateWaveform(String filepath, int sampleCount) {
    if (!isNativeAvailable) {
      debugPrint('Native library not available for waveform generation');
   return null;
  }

    if (NativeBindings.audioWaveform == null) {
      debugPrint('audioWaveform function not found in native library');
      return null;
    }

    final pathPtr = filepath.toNativeUtf8();
    final waveformPtr = calloc<AudioWaveform>();

    try {
      debugPrint('Calling audio_generate_waveform for: $filepath');
      final result = NativeBindings.audioWaveform!(
        pathPtr,
        waveformPtr,
        sampleCount,
      );

      debugPrint('audio_generate_waveform returned: $result');
      
      if (result == 0) {
        final waveform = waveformPtr.ref;
   debugPrint('Waveform: samples ptr=${waveform.samples.address}, count=${waveform.sampleCount}');

        if (waveform.samples.address != 0 && waveform.sampleCount > 0) {
  final samples = <double>[];
    try {
            for (int i = 0; i < waveform.sampleCount; i++) {
          samples.add(waveform.samples[i].toDouble());
 }
          debugPrint('Successfully converted ${samples.length} waveform samples');
          } catch (e) {
         debugPrint('Error reading waveform samples: $e');
            return null;
}
  
        if (NativeBindings.audioReleaseWaveform != null) {
            NativeBindings.audioReleaseWaveform!(waveformPtr);
          }
          return samples;
        } else {
        debugPrint('No audio waveform data (video might not have audio)');
       return null;
 }
      } else {
        debugPrint('Waveform generation failed with error code: $result');
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in generateWaveform: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      calloc.free(pathPtr);
      calloc.free(waveformPtr);
    }

    return null;
  }
}

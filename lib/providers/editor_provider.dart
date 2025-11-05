import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';  // NEW: For Directory
import 'package:flutter/foundation.dart';
import 'package:ffi/ffi.dart';  // For malloc
import '../native/video_engine_wrapper.dart';
import '../native/bindings.dart';
import '../audio/audio_playback_manager.dart';  // NEW: Import audio manager
import '../models/text_layer_data.dart';  // NEW: Import text layer model
import '../widgets/video_preview.dart'; // NEW: Import for aspect ratio enums

class EditorState {
  final TimelineController timeline;
  final int previewWidth; // target width for HQ preview
  final int previewHeight; // target height for HQ preview
  final List<ClipData> clips;
  final int? selectedClipId;
  final int currentTimeMs;
  final bool isPlaying;
  final double zoom;
  final int scrollOffset;
  final Map<int, VideoMetadataData> clipMetadata;
  final Map<int, List<double>> clipWaveforms;
  final Map<int, int> originalDurations;
  final Map<int, String> clipFilePaths;  // NEW: Store file paths for audio playback
  final bool snapEnabled;  // NEW: Auto-snapping toggle
  final int trackCount;  // NEW: Dynamic track count
  final List<TextLayerData> textLayers;  // NEW: Text layers
  final int? selectedTextLayerId;  // NEW: Selected text layer
  final List<TrackData> tracks;  // NEW: Track metadata
  
  // NEW: Aspect ratio and quality settings
  final AspectRatioPreset aspectRatio;
  final VideoQuality quality;
  final int customWidth;   // Used when aspectRatio or quality is custom
  final int customHeight;  // Used when aspectRatio or quality is custom

  const EditorState({
    required this.timeline,
    this.clips = const [],
    this.selectedClipId,
    this.currentTimeMs = 0,
    this.isPlaying = false,
    this.zoom = 1.0,
    this.scrollOffset = 0,
    this.clipMetadata = const {},
    this.clipWaveforms = const {},
    this.originalDurations = const {},
    this.clipFilePaths = const {},  // NEW
    this.snapEnabled = true,  // NEW: Default ON
    this.trackCount = 3,  // NEW: Default 3 tracks
    this.textLayers = const [],  // NEW
    this.selectedTextLayerId,  // NEW
    this.tracks = const [],  // NEW
    this.previewWidth = 1920,
    this.previewHeight = 1080,
    this.aspectRatio = AspectRatioPreset.widescreen,  // NEW: Default 16:9
    this.quality = VideoQuality.quality1080p,          // NEW: Default 1080p
    this.customWidth = 1920,                // NEW
    this.customHeight = 1080,               // NEW
  });
  
  // NEW: Calculate export dimensions based on aspect ratio and quality
  int get exportWidth {
    if (quality == VideoQuality.custom || aspectRatio == AspectRatioPreset.custom) {
      return customWidth;
    }
    
    final baseHeight = quality.height!;
  final ratio = aspectRatio.ratio!;
    
    // For portrait ratios (< 1.0), swap width and height calculation
    if (ratio < 1.0) {
      // Portrait: height is larger
      return baseHeight;
 } else {
      // Landscape or square: width is larger
 return (baseHeight * ratio).round();
    }
  }
  
  int get exportHeight {
    if (quality == VideoQuality.custom || aspectRatio == AspectRatioPreset.custom) {
   return customHeight;
    }
    
    final baseHeight = quality.height!;
    final ratio = aspectRatio.ratio!;
    
    if (ratio < 1.0) {
   // Portrait: calculate height from ratio
      return (baseHeight / ratio).round();
    } else {
      // Landscape or square
      return baseHeight;
    }
  }

  EditorState copyWith({
    TimelineController? timeline,
    int? previewWidth,
    int? previewHeight,
    List<ClipData>? clips,
    int? selectedClipId,
    bool clearSelection = false,
    int? currentTimeMs,
    bool? isPlaying,
    double? zoom,
    int? scrollOffset,
    Map<int, VideoMetadataData>? clipMetadata,
    Map<int, List<double>>? clipWaveforms,
    Map<int, int>? originalDurations,
    Map<int, String>? clipFilePaths,
    bool? snapEnabled,
    int? trackCount,
    List<TextLayerData>? textLayers,  // NEW
    int? selectedTextLayerId,  // NEW
    bool clearTextSelection = false,  // NEW
    List<TrackData>? tracks,  // NEW
    AspectRatioPreset? aspectRatio,  // NEW
    VideoQuality? quality,  // NEW
    int? customWidth,  // NEW
    int? customHeight,  // NEW
  }) {
    return EditorState(
      timeline: timeline ?? this.timeline,
      previewWidth: previewWidth ?? this.previewWidth,
      previewHeight: previewHeight ?? this.previewHeight,
      clips: clips ?? this.clips,
      selectedClipId: clearSelection ? null : (selectedClipId ?? this.selectedClipId),
      currentTimeMs: currentTimeMs ?? this.currentTimeMs,
      isPlaying: isPlaying ?? this.isPlaying,
      zoom: zoom ?? this.zoom,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      clipMetadata: clipMetadata ?? this.clipMetadata,
      clipWaveforms: clipWaveforms ?? this.clipWaveforms,
      originalDurations: originalDurations ?? this.originalDurations,
      clipFilePaths: clipFilePaths ?? this.clipFilePaths,
      snapEnabled: snapEnabled ?? this.snapEnabled,
      trackCount: trackCount ?? this.trackCount,
      textLayers: textLayers ?? this.textLayers,  // NEW
      selectedTextLayerId: clearTextSelection ? null : (selectedTextLayerId ?? this.selectedTextLayerId),  // NEW
      tracks: tracks ?? this.tracks,  // NEW
      aspectRatio: aspectRatio ?? this.aspectRatio,  // NEW
      quality: quality ?? this.quality,  // NEW
      customWidth: customWidth ?? this.customWidth,  // NEW
      customHeight: customHeight ?? this.customHeight,  // NEW
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorState &&
   runtimeType == other.runtimeType &&
   selectedClipId == other.selectedClipId &&
          currentTimeMs == other.currentTimeMs &&
     isPlaying == other.isPlaying &&
          zoom == other.zoom &&
          scrollOffset == other.scrollOffset &&
     clips.length == other.clips.length;

  @override
  int get hashCode =>
      selectedClipId.hashCode ^
      currentTimeMs.hashCode ^
      isPlaying.hashCode ^
      zoom.hashCode ^
   scrollOffset.hashCode ^
      clips.length.hashCode;
}

class EditorNotifier extends StateNotifier<EditorState> {
  Timer? _playbackTimer;
  late AudioPlaybackManager _audioManager;  // NEW: Audio manager
  static const int _playbackFps = 30;
  static const int _frameTimeMs = 1000 ~/ _playbackFps;
  int _nextTextLayerId = 1;  // NEW: Text layer ID counter
  bool _batchingUpdates = false; // NEW: Flag to batch undo states
  
  EditorNotifier() : super(EditorState(timeline: TimelineController())) {
    _audioManager = AudioPlaybackManager();  // NEW: Initialize audio manager
    _loadClips();
    _loadTracks();  // NEW: Load track metadata
  }

  void _loadClips() {
    final clips = state.timeline.getAllClips();
    state = state.copyWith(clips: clips);
}

  void _loadTracks() {
    final tracks = state.timeline.getAllTracks();
    state = state.copyWith(tracks: tracks);
  }
  
  // NEW: Start batching updates (don't push undo state for each operation)
  void beginBatchUpdate() {
    _batchingUpdates = true;
  }
  
  // NEW: End batching and push single undo state
  void endBatchUpdate() {
 _batchingUpdates = false;
    state.timeline.pushState(); // Push single state for entire batch
    _loadClips();
    _loadTracks();
  }
  
  Future<void> addClip(String filepath, {int trackIndex = 0}) async {
    try {
      debugPrint('ADD_CLIP: === Adding clip ===');
   debugPrint('ADD_CLIP: Filepath: $filepath');
      debugPrint('ADD_CLIP: Target track: $trackIndex');
    
      if (filepath.isEmpty) {
debugPrint('ADD_CLIP: ERROR: Empty filepath');
        return;
  }
 
      // Validate track exists and get track type
      TrackType? targetTrackType;
if (state.tracks.isNotEmpty) {
   final track = state.tracks.firstWhere(
          (t) => t.trackId == trackIndex,
 orElse: () => state.tracks.first,
  );
  targetTrackType = track.trackType;
   trackIndex = track.trackId;
        debugPrint('ADD_CLIP: Target track type: $targetTrackType');
  }
      
      // First, add the clip to timeline to determine if it's video or audio-only
      debugPrint('ADD_CLIP: Adding clip to native timeline...');
      final clipId = state.timeline.addClip(
   filepath,
 trackIndex: trackIndex,
      startTimeMs: state.currentTimeMs,
    );

   if (clipId < 0) {
        debugPrint('ADD_CLIP: ERROR: Failed to add clip to timeline (ID: $clipId)');
        return;
   }
      
   debugPrint('ADD_CLIP: Clip added with ID: $clipId');
  
// Store filepath for ALL clips immediately (CRITICAL FIX)
      final updatedFilePaths = {...state.clipFilePaths, clipId: filepath};
   state = state.copyWith(clipFilePaths: updatedFilePaths);
      debugPrint('ADD_CLIP: Stored filepath mapping for clip $clipId');
    
      _loadClips();
    
   // Get the clip to check if it's audio-only or video
    final clip = state.clips.firstWhere((c) => c.clipId == clipId, orElse: () => ClipData(
     clipId: -1,
        startTimeMs: 0,
   endTimeMs: 0,
trimStartMs: 0,
trimEndMs: 0,
   ));
 
   if (clip.clipId == -1) {
        debugPrint('ADD_CLIP: ERROR: Could not find clip after adding');
        return;
      }

  debugPrint('ADD_CLIP: Clip info - isAudioOnly: ${clip.isAudioOnly}, duration: ${clip.durationMs}ms');

 // Validate track type matches clip type
if (targetTrackType != null) {
    if (targetTrackType == TrackType.audio && !clip.isAudioOnly) {
        debugPrint('ADD_CLIP: Warning: Video clip added to audio track');
   }
      if (targetTrackType == TrackType.text) {
        debugPrint('ADD_CLIP: Error: Cannot add media clips to text track');
      removeClip(clipId);
     return;
      }
    }

      // If it's a VIDEO file (not audio-only), extract audio and create separate audio clip
    if (!clip.isAudioOnly) {
   debugPrint('ADD_CLIP: Video clip detected, will extract audio');
   await _splitVideoIntoVideoAndAudioClips(clipId, filepath, clip);
  } else {
      // It's audio-only, just register normally
   debugPrint('ADD_CLIP: Audio-only clip, registering for playback');
     _audioManager.registerClip(clipId, filepath, isAudioOnly: true);
      }
      
// Load metadata asynchronously
      debugPrint('ADD_CLIP: Loading metadata...');
    _loadClipMetadata(clipId, filepath);
      
   debugPrint('ADD_CLIP: === Clip added successfully ===');
    } catch (e, stackTrace) {
      debugPrint('ADD_CLIP: FATAL ERROR: $e');
 debugPrint('ADD_CLIP: Stack trace: $stackTrace');
    }
  }

  Future<void> _splitVideoIntoVideoAndAudioClips(int videoClipId, String videoPath, ClipData videoClip) async {
 try {
debugPrint('SPLIT_AUDIO: === Starting audio extraction for clip $videoClipId ===');
debugPrint('SPLIT_AUDIO: Video path: $videoPath');
  debugPrint('SPLIT_AUDIO: Video clip: ${videoClip.startTimeMs}-${videoClip.endTimeMs}ms, duration: ${videoClip.durationMs}ms');
      
      // Register the video clip for playback (even though it will be muted)
      debugPrint('SPLIT_AUDIO: Registering video clip $videoClipId for playback');
   _audioManager.registerClip(videoClipId, videoPath, isAudioOnly: false);
    
   // Create temp directory for extracted audio
   final tempDir = Directory.systemTemp.createTempSync('videocut_audio_');
final audioFileBasePath = '${tempDir.path}/audio_$videoClipId.mp3';
  debugPrint('SPLIT_AUDIO: Temp audio path: $audioFileBasePath');
  
      // Extract audio from video using C++ FFmpeg
      debugPrint('SPLIT_AUDIO: Calling extractAudioFromVideo...');
      final extractedAudioPath = await compute(_extractAudioIsolate, {
'videoPath': videoPath,
    'outputPath': audioFileBasePath,
 });

      debugPrint('SPLIT_AUDIO: Extraction result: $extractedAudioPath');
      
   if (extractedAudioPath == null || extractedAudioPath.isEmpty) {
   debugPrint('SPLIT_AUDIO: Failed to extract audio, video will play without audio');
 return;
 }
      
   debugPrint('SPLIT_AUDIO: Audio extracted successfully to: $extractedAudioPath');
   
 // Mute the original video clip (since audio will be in separate clip)
      debugPrint('SPLIT_AUDIO: Muting original video clip $videoClipId');
 state.timeline.muteClip(videoClipId, true);
      
      // Find the first AUDIO track, or create one if none exists
  debugPrint('SPLIT_AUDIO: Looking for AUDIO track...');
   TrackData? audioTrack = state.tracks.firstWhere(
      (t) => t.trackType == TrackType.audio,
        orElse: () => TrackData(
  trackId: -1,
    trackType: TrackType.audio,
     trackName: '',
        displayOrder: 0,
          isLocked: false,
          isVisible: true,
   opacity: 1.0,
        ),
      );
      
 // If no audio track exists, create one
      if (audioTrack.trackId == -1) {
  debugPrint('SPLIT_AUDIO: No AUDIO track found, creating one...');
 final newTrackId = state.timeline.addTrack(TrackType.audio, name: 'Audio 1');
  if (newTrackId >= 0) {
      debugPrint('SPLIT_AUDIO: Created AUDIO track with ID: $newTrackId');
            _loadTracks();
      audioTrack = state.tracks.firstWhere((t) => t.trackId == newTrackId);
    } else {
      debugPrint('SPLIT_AUDIO: ERROR: Failed to create audio track');
            return;
        }
  } else {
        debugPrint('SPLIT_AUDIO: Found existing AUDIO track: ${audioTrack.trackId}');
    }
    
 // Create a new audio clip on the AUDIO track at the same position
      debugPrint('SPLIT_AUDIO: Adding audio clip to track ${audioTrack.trackId}...');
      final audioClipId = state.timeline.addClip(
        extractedAudioPath,
        trackIndex: audioTrack.trackId,
    startTimeMs: videoClip.startTimeMs,
  );
  
      debugPrint('SPLIT_AUDIO: Audio clip created with ID: $audioClipId');
      
 if (audioClipId > 0) {
// Store the extracted audio file path
      final updatedFilePaths = {...state.clipFilePaths, audioClipId: extractedAudioPath};
   state = state.copyWith(clipFilePaths: updatedFilePaths);
   debugPrint('SPLIT_AUDIO: Stored file path mapping for audio clip');
   
     // Register audio clip for playback
        debugPrint('SPLIT_AUDIO: Registering audio clip for playback...');
        try {
  _audioManager.registerClip(audioClipId, extractedAudioPath, isAudioOnly: true);
        debugPrint('SPLIT_AUDIO: Audio clip registered successfully');
        } catch (e, stackTrace) {
   debugPrint('SPLIT_AUDIO: ERROR registering audio clip: $e');
   debugPrint('SPLIT_AUDIO: Stack trace: $stackTrace');
        }
 
     // Ensure audio clip has same duration as video clip
    debugPrint('SPLIT_AUDIO: Trimming audio clip to match video duration (${videoClip.durationMs}ms)');
        state.timeline.trimClip(audioClipId, 0, videoClip.durationMs);
   
  _loadClips();
  
        debugPrint('SPLIT_AUDIO: === Audio extraction complete for clip $videoClipId ===');
   
   // NEW: Load metadata and waveform for the audio clip
     debugPrint('SPLIT_AUDIO: Loading metadata for audio clip...');
 try {
    _loadClipMetadata(audioClipId, extractedAudioPath);
          debugPrint('SPLIT_AUDIO: Metadata loading started');
 } catch (e, stackTrace) {
          debugPrint('SPLIT_AUDIO: ERROR loading metadata: $e');
   debugPrint('SPLIT_AUDIO: Stack trace: $stackTrace');
 }
      } else {
        debugPrint('SPLIT_AUDIO: ERROR: Failed to create audio clip (ID: $audioClipId)');
      }
    } catch (e, stackTrace) {
    debugPrint('SPLIT_AUDIO: FATAL ERROR in _splitVideoIntoVideoAndAudioClips: $e');
      debugPrint('SPLIT_AUDIO: Stack trace: $stackTrace');
    }
  }

  static String? _extractAudioIsolate(Map<String, String> params) {
   return extractAudioFromVideo(params['videoPath']!, params['outputPath']!);
  }
  Future<void> _loadClipMetadata(int clipId, String filepath) async {
    try {
      // Get the clip to check its type
      final clip = state.clips.firstWhere((c) => c.clipId == clipId, orElse: () => ClipData(
        clipId: -1,
        startTimeMs: 0,
endTimeMs: 0,
        trimStartMs: 0,
        trimEndMs: 0,
      ));
      
      if (clip.clipId == -1) return;
    
      // For audio-only clips, create metadata from audio info
      VideoMetadataData? metadata;
   if (clip.isAudioOnly) {
        // For audio clips, get metadata directly (not in isolate due to FFI limitations)
      final audioMeta = AudioMetadata.getMetadata(filepath);
        if (audioMeta != null) {
          // Create a VideoMetadataData from audio info (for compatibility)
   metadata = VideoMetadataData(
     durationMs: audioMeta.durationMs,
            width: 1920,  // Dummy values for audio
            height: 1080,
       frameRate: 30.0,
 bitrate: 128000,
     codec: 'audio',
   audioChannels: audioMeta.channels,
     audioSampleRate: audioMeta.sampleRate,
       );
        }
   } else {
        // For video clips, use video metadata
        metadata = await compute(_getMetadataIsolate, filepath);
   }
      
      if (metadata == null) return;

      final updatedMetadata = {...state.clipMetadata, clipId: metadata};
      final updatedDurations = {...state.originalDurations, clipId: metadata.durationMs};
  
      // Generate waveform in isolate (works for both video and audio)
  final waveform = await compute(_generateWaveformIsolate, filepath);
      final Map<int, List<double>> updatedWaveforms = {...state.clipWaveforms};
      if (waveform != null && waveform.isNotEmpty) {
        updatedWaveforms[clipId] = waveform;
      }
      
      state = state.copyWith(
        clipMetadata: updatedMetadata,
        clipWaveforms: updatedWaveforms,
        originalDurations: updatedDurations,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Metadata load error: $e');
    }
  }
  
  static VideoMetadataData? _getMetadataIsolate(String filepath) {
    return VideoMetadataData.getMetadata(filepath);
  }
  
  static List<double>? _generateWaveformIsolate(String filepath) {
    return VideoMetadataData.generateWaveform(filepath, 200);
  }

  void removeClip(int clipId) {
    if (state.timeline.removeClip(clipId)) {
   _audioManager.unregisterClip(clipId);  // NEW: Unregister from audio manager
  _loadClips();
      if (state.selectedClipId == clipId) {
        state = state.copyWith(clearSelection: true);
      }
    }
  }

  void selectClip(int? clipId) {
    if (clipId != null && !state.clips.any((c) => c.clipId == clipId)) return;
 state = state.copyWith(selectedClipId: clipId);
  }

  void updateClip(int clipId, ClipData data) {
    if (state.timeline.updateClip(clipId, data)) {
      _loadClips();
    }
  }

  void splitClip(int clipId) {
    if (!state.clips.any((c) => c.clipId == clipId)) return;
 
    final newId = state.timeline.splitClip(clipId, state.currentTimeMs);
    if (newId != null) {
      _loadClips();
      
      // NEW: Handle audio registration and metadata for the new clip
final originalClip = state.clips.firstWhere((c) => c.clipId == clipId, orElse: () => ClipData(
  clipId: -1,
startTimeMs: 0,
  endTimeMs: 0,
 trimStartMs: 0,
    trimEndMs: 0,
      ));
      
 if (originalClip.clipId != -1) {
      // Copy file path mapping from original to new clip
   final originalFilePath = state.clipFilePaths[clipId];
    if (originalFilePath != null) {
   final updatedFilePaths = {...state.clipFilePaths, newId: originalFilePath};
      state = state.copyWith(clipFilePaths: updatedFilePaths);
          
// Register new clip for audio playback
       _audioManager.registerClip(newId, originalFilePath, isAudioOnly: originalClip.isAudioOnly);
          
// Copy metadata from original clip
  final originalMetadata = state.clipMetadata[clipId];
          if (originalMetadata != null) {
   final updatedMetadata = {...state.clipMetadata, newId: originalMetadata};
   state = state.copyWith(clipMetadata: updatedMetadata);
 }
      
          // Copy original duration
 final originalDuration = state.originalDurations[clipId];
       if (originalDuration != null) {
  final updatedDurations = {...state.originalDurations, newId: originalDuration};
            state = state.copyWith(originalDurations: updatedDurations);
          }
          
  // Copy waveform from original clip
   final originalWaveform = state.clipWaveforms[clipId];
     if (originalWaveform != null) {
          final updatedWaveforms = {...state.clipWaveforms, newId: originalWaveform};
state = state.copyWith(clipWaveforms: updatedWaveforms);
        }
   
   if (kDebugMode) {
     debugPrint('Split clip $clipId into $newId - audio and metadata copied');
}
  }
      }
    }
  }

  void trimClip(int clipId, int trimStartMs, int trimEndMs) {
    if (trimStartMs < 0 || trimEndMs < trimStartMs) return;
 
    if (state.timeline.trimClip(clipId, trimStartMs, trimEndMs)) {
      _loadClips();
    }
  }

  void setClipSpeed(int clipId, double speed) {
    if (speed <= 0 || speed > 10) return;
    
    if (state.timeline.setClipSpeed(clipId, speed)) {
      _loadClips();
    }
  }

  void setClipVolume(int clipId, double volume) {
    if (volume < 0 || volume > 2) return;
    
    if (state.timeline.setClipVolume(clipId, volume)) {
      _loadClips();
    }
  }

  void muteClip(int clipId, bool muted) {
 if (state.timeline.muteClip(clipId, muted)) {
   _loadClips();
    }
  }

  void setClipScale(int clipId, double scaleX, double scaleY) {
  // Clamp to 1%-500% range
    scaleX = scaleX.clamp(0.01, 5.0);
    scaleY = scaleY.clamp(0.01, 5.0);
    
    if (state.timeline.setClipScale(clipId, scaleX, scaleY)) {
      _loadClips();
    }
  }

  void toggleClipAspectLock(int clipId) {
    final clip = state.clips.firstWhere((c) => c.clipId == clipId, orElse: () => ClipData(
      clipId: -1,
      startTimeMs: 0,
      endTimeMs: 0,
      trimStartMs: 0,
      trimEndMs: 0,
    ));
    
    if (clip.clipId == -1) return;
    
    final newLocked = !clip.lockAspectRatio;
    if (state.timeline.setClipAspectLock(clipId, newLocked)) {
      _loadClips();
    }
  }

  void seekTo(int timeMs) {
    timeMs = timeMs.clamp(0, state.timeline.getDuration());
 _audioManager.seek(timeMs);  // NEW: Seek audio
    _currentlyPlayingClipIds.clear();  // NEW: Clear playing clips set
    state = state.copyWith(currentTimeMs: timeMs, isPlaying: false);
  }

  void play() async {  // NEW: Make async
    try {
      debugPrint('=== PLAY: Starting playback ===');
      debugPrint('PLAY: Current time: ${state.currentTimeMs}ms');
      debugPrint('PLAY: Total clips: ${state.clips.length}');
      
      state = state.copyWith(isPlaying: true);

      // Get active clips at current time
  final activeClips = _getActiveClipsAt(state.currentTimeMs);
      debugPrint('PLAY: Active clips at ${state.currentTimeMs}ms: ${activeClips.length}');
      for (final clip in activeClips) {
     debugPrint('PLAY: Clip ${clip.clipId}: ${clip.startTimeMs}-${clip.endTimeMs}ms, audioOnly: ${clip.isAudioOnly}, track: ${clip.trackIndex}');
    }
      
      _currentlyPlayingClipIds = activeClips.map((c) => c.clipId).toSet();
      
      // Start audio playback
      debugPrint('PLAY: Starting audio playback...');
      try {
      await _audioManager.play(activeClips, state.currentTimeMs);
        debugPrint('PLAY: Audio playback started successfully');
 } catch (e, stackTrace) {
        debugPrint('PLAY: ERROR in audio playback: $e');
        debugPrint('PLAY: Stack trace: $stackTrace');
      }
      
      _playbackTimer?.cancel();
      debugPrint('PLAY: Starting playback timer (${_frameTimeMs}ms interval)');
      
      _playbackTimer = Timer.periodic(Duration(milliseconds: _frameTimeMs), (timer) {
        try {
    if (!state.isPlaying) {
          debugPrint('PLAY: Stopped, canceling timer');
 timer.cancel();
            return;
   }

        final duration = state.timeline.getDuration();
          if (state.currentTimeMs >= duration) {
     debugPrint('PLAY: Reached end of timeline');
pause();
  seekTo(0);
        return;
     }
 
    final newTimeMs = state.currentTimeMs + _frameTimeMs;
          state = state.copyWith(currentTimeMs: newTimeMs);
      
          // Update audio playback when active clips change (check less frequently for performance)
 if (timer.tick % 3 == 0) {  // Check every 3 frames (~100ms) instead of every frame
      try {
              _updateAudioPlayback(newTimeMs);
  } catch (e, stackTrace) {
      debugPrint('PLAY: ERROR in _updateAudioPlayback: $e');
        debugPrint('PLAY: Stack trace: $stackTrace');
   }
    }
        } catch (e, stackTrace) {
      debugPrint('PLAY: ERROR in playback timer: $e');
       debugPrint('PLAY: Stack trace: $stackTrace');
    timer.cancel();
   pause();
        }
      });
      
      debugPrint('PLAY: Playback started successfully');
    } catch (e, stackTrace) {
      debugPrint('PLAY: FATAL ERROR in play(): $e');
      debugPrint('PLAY: Stack trace: $stackTrace');
      state = state.copyWith(isPlaying: false);
    }
  }

  // NEW: Track which clips are currently playing
  Set<int> _currentlyPlayingClipIds = {};

  // NEW: Update audio playback when playhead moves
  void _updateAudioPlayback(int timeMs) async {
    try {
 debugPrint('UPDATE_AUDIO: Checking at ${timeMs}ms');

  final activeClips = _getActiveClipsAt(timeMs);
      final activeClipIds = activeClips.map((c) => c.clipId).toSet();
      
      debugPrint('UPDATE_AUDIO: Active clip IDs: $activeClipIds');
      debugPrint('UPDATE_AUDIO: Previously playing: $_currentlyPlayingClipIds');
      
      // Check if the set of active clips has changed
      final hasChanged = activeClipIds.length != _currentlyPlayingClipIds.length ||
          !activeClipIds.every((id) => _currentlyPlayingClipIds.contains(id)) ||
!_currentlyPlayingClipIds.every((id) => activeClipIds.contains(id));
  
    if (hasChanged) {
      debugPrint('UPDATE_AUDIO: Active clips changed, restarting audio');
        
        _currentlyPlayingClipIds = activeClipIds;
        
    try {
      await _audioManager.stopAll();
     debugPrint('UPDATE_AUDIO: Stopped all audio');
    } catch (e, stackTrace) {
          debugPrint('UPDATE_AUDIO: ERROR stopping audio: $e');
 debugPrint('UPDATE_AUDIO: Stack trace: $stackTrace');
        }

        if (activeClips.isNotEmpty && state.isPlaying) {
          try {
      await _audioManager.play(activeClips, timeMs);
     debugPrint('UPDATE_AUDIO: Started audio for ${activeClips.length} clips');
      } catch (e, stackTrace) {
            debugPrint('UPDATE_AUDIO: ERROR starting audio: $e');
            debugPrint('UPDATE_AUDIO: Stack trace: $stackTrace');
   }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('UPDATE_AUDIO: FATAL ERROR: $e');
      debugPrint('UPDATE_AUDIO: Stack trace: $stackTrace');
    }
  }

  void pause() async {  // NEW: Make async
    _playbackTimer?.cancel();
    _playbackTimer = null;
    await _audioManager.pause();  // NEW: Pause audio
    _currentlyPlayingClipIds.clear();  // NEW: Clear playing clips set
    state = state.copyWith(isPlaying: false);
  }

  // NEW: Helper to get active clips at a specific time
  List<ClipData> _getActiveClipsAt(int timeMs) {
    return state.clips.where((clip) {
  return timeMs >= clip.startTimeMs && timeMs < clip.endTimeMs;
    }).toList();
  }

  int _findFreePosition(int trackIndex, int preferredStartMs) {
  final clipsOnTrack = state.clips
        .where((c) => c.trackIndex == trackIndex)
        .toList()
    ..sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));
    
 if (clipsOnTrack.isEmpty) {
      return preferredStartMs;
    }
    
    bool hasCollision = clipsOnTrack.any((clip) {
      return preferredStartMs < clip.endTimeMs && 
          (preferredStartMs + 1000) > clip.startTimeMs;
    });
    
    if (!hasCollision) {
      return preferredStartMs;
    }
    
    for (int i = 0; i < clipsOnTrack.length; i++) {
      final currentClip = clipsOnTrack[i];
   
   if (i < clipsOnTrack.length - 1) {
        final nextClip = clipsOnTrack[i + 1];
        final gapStart = currentClip.endTimeMs;
        final gapEnd = nextClip.startTimeMs;
     
        if (gapEnd - gapStart >= 1000) {
          return gapStart;
        }
      } else {
        return currentClip.endTimeMs;
  }
    }
    
    return 0;
  }

  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom.clamp(0.1, 10.0));
  }

  void scroll(int offset) {
    if (offset < 0) return;
    state = state.copyWith(scrollOffset: offset);
  }

  // NEW: Toggle snap to grid
  void toggleSnap() {
    state = state.copyWith(snapEnabled: !state.snapEnabled);
  }
  
  // NEW: Aspect ratio and quality settings
  void setAspectRatio(AspectRatioPreset ratio) {
    state = state.copyWith(aspectRatio: ratio);
  }

  void setQuality(VideoQuality quality) {
    state = state.copyWith(quality: quality);
  }

  void setCustomResolution(int width, int height) {
    state = state.copyWith(
      customWidth: width,
      customHeight: height,
      aspectRatio: AspectRatioPreset.custom,
      quality: VideoQuality.custom,
    );
  }
 
  // NEW: Add a new track
  void addTrack() {
    final newTrackCount = state.trackCount + 1;
  if (newTrackCount <= 10) {  // Maximum 10 tracks
      state = state.copyWith(trackCount: newTrackCount);
    }
  }

  // NEW: Remove last track (if no clips on it)
  void removeTrack() {
    if (state.trackCount <= 1) return;  // Keep at least 1 track
    
    // Check if last track has any clips
 final lastTrackIndex = state.trackCount - 1;
    final hasClipsOnLastTrack = state.clips.any((clip) => clip.trackIndex == lastTrackIndex);
    
    if (!hasClipsOnLastTrack) {
      state = state.copyWith(trackCount: state.trackCount - 1);
    }
  }

  // NEW: Add track with metadata
  void addTrackWithType(TrackType trackType, {String? name}) {
    final trackId = state.timeline.addTrack(trackType, name: name);
    if (trackId >= 0) {
      _loadTracks();
    }
  }

  // NEW: Remove track by ID
  void removeTrackById(int trackId) {
    if (state.timeline.removeTrack(trackId)) {
      _loadTracks();
    }
  }

  // NEW: Swap track positions
  void swapTrackPositions(int trackA, int trackB) {
    if (state.timeline.swapTracks(trackA, trackB)) {
      _loadTracks();
      _loadClips();  // Clips moved with tracks
 }
  }

  // NEW: Text layer management
  void addTextLayer() {
    // Find the first TEXT track, or create one if none exists
    TrackData? textTrack = state.tracks.firstWhere(
      (t) => t.trackType == TrackType.text,
      orElse: () => TrackData(
   trackId: -1,
        trackType: TrackType.text,
        trackName: '',
        displayOrder: 0,
        isLocked: false,
        isVisible: true,
        opacity: 1.0,
 ),
);
    
    // If no text track exists, create one
    if (textTrack.trackId == -1) {
debugPrint('ADD_TEXT: No TEXT track found, creating one...');
      final newTrackId = state.timeline.addTrack(TrackType.text, name: 'Text 1');
      if (newTrackId >= 0) {
 debugPrint('ADD_TEXT: Created TEXT track with ID: $newTrackId');
        _loadTracks();
        // Reload tracks to get the newly created track
     textTrack = state.tracks.firstWhere(
          (t) => t.trackId == newTrackId,
          orElse: () {
            debugPrint('ADD_TEXT: ERROR: Could not find newly created track!');
            return TrackData(
   trackId: -1,
          trackType: TrackType.text,
     trackName: '',
          displayOrder: 0,
       isLocked: false,
          isVisible: true,
              opacity: 1.0,
       );
     },
        );
        
        if (textTrack.trackId == -1) {
          debugPrint('ADD_TEXT: ERROR: Failed to load new track after creation');
          return;
        }
      } else {
        debugPrint('ADD_TEXT: ERROR: Failed to create text track (ID: $newTrackId)');
        return;
      }
    }
    
    debugPrint('ADD_TEXT: Using TEXT track ID: ${textTrack.trackId}, name: ${textTrack.trackName}');
    
    final newLayer = TextLayerData(
      layerId: _nextTextLayerId++,
      text: 'New Text',
      startTimeMs: state.currentTimeMs,
      endTimeMs: state.currentTimeMs + 5000,  // 5 seconds default
      trackIndex: textTrack.trackId,  // Use the TEXT track ID
    x: 0.5,  // center X (normalized 0-1)
      y: 0.5,  // center Y (normalized 0-1)
      fontSize: 48,
    );
    
    debugPrint('ADD_TEXT: Creating text layer with trackIndex: ${newLayer.trackIndex}');
    
  final updatedLayers = [...state.textLayers, newLayer];
    state = state.copyWith(
  textLayers: updatedLayers,
      selectedTextLayerId: newLayer.layerId,
      clearSelection: true,  // Deselect clips
    );
    
    debugPrint('ADD_TEXT: Created text layer ${newLayer.layerId} on track ${textTrack.trackId} (${textTrack.trackName})');
    
    // Sync to native timeline immediately
    syncTextLayersToNative();
  }

  void removeTextLayer(int layerId) {
    final updatedLayers = state.textLayers.where((l) => l.layerId != layerId).toList();
    state = state.copyWith(
textLayers: updatedLayers,
      clearTextSelection: true,
    );
  }

  void selectTextLayer(int? layerId) {
    state = state.copyWith(
      selectedTextLayerId: layerId,
      clearSelection: true,  // Deselect clips when selecting text
    );
  }

  void updateTextLayer(int layerId, TextLayerData updatedLayer) {
    final updatedLayers = state.textLayers.map((layer) {
      return layer.layerId == layerId ? updatedLayer : layer;
    }).toList();
    
    state = state.copyWith(textLayers: updatedLayers);
    
    // Sync to native immediately
    syncTextLayersToNative();
  }

  void moveTextLayer(int layerId, int newStartTimeMs) {
    final layer = state.textLayers.firstWhere(
      (l) => l.layerId == layerId,
      orElse: () => TextLayerData(layerId: -1, startTimeMs: 0, endTimeMs: 0),
    );
  
    if (layer.layerId == -1) return;
    
    final duration = layer.durationMs;
    final updatedLayer = layer.copyWith(
      startTimeMs: newStartTimeMs.clamp(0, 600000),
      endTimeMs: newStartTimeMs + duration,
    );
    
    updateTextLayer(layerId, updatedLayer);
  }

  void syncTextLayersToNative() {
    if (kDebugMode) debugPrint('Syncing ${state.textLayers.length} text layers to native timeline');
    
    // Clear existing text layers in native timeline
    final nativeTextLayers = state.timeline.getAllTextLayers();
    for (final layer in nativeTextLayers) {
      state.timeline.removeTextLayer(layer.layerId);
    }
    
    // Add all current text layers to native timeline
    for (final layer in state.textLayers) {
      if (kDebugMode) debugPrint('  Syncing text layer ${layer.layerId}: "${layer.text}" at (${layer.x}, ${layer.y}) color: ${layer.textColor}');
      
      state.timeline.addTextLayer(layer);
    }
    
    if (kDebugMode) debugPrint('Text layer sync complete');
  }
  
  void undo() {
    if (state.timeline.undo()) {
      // Reload all state from C++ after undo
      _loadClips();
      _loadTracks();
      // Reload text layers
      final textLayers = state.timeline.getAllTextLayers();
      state = state.copyWith(
     textLayers: textLayers,
        clearSelection: true, // Deselect on undo
        clearTextSelection: true,
      );
    }
  }

  void redo() {
    if (state.timeline.redo()) {
   // Reload all state from C++ after redo
      _loadClips();
_loadTracks();
      // Reload text layers
      final textLayers = state.timeline.getAllTextLayers();
   state = state.copyWith(
      textLayers: textLayers,
        clearSelection: true, // Deselect on redo
        clearTextSelection: true,
  );
    }
  }

  bool canUndo() => state.timeline.canUndo();
  bool canRedo() => state.timeline.canRedo();
  
  void clearUndoHistory() {
    state.timeline.clearHistory();
  }

  void moveClip(int clipId, int newStartTimeMs, {int? newTrackIndex}) {
    final clip = state.clips.firstWhere((c) => c.clipId == clipId, orElse: () => ClipData(
      clipId: -1,
      startTimeMs: 0,
      endTimeMs: 0,
      trimStartMs: 0,
      trimEndMs: 0,
    ));
    
    if (clip.clipId == -1) return;
  
    final duration = clip.durationMs;
    final updated = clip.copyWith(
      startTimeMs: newStartTimeMs,
      endTimeMs: newStartTimeMs + duration,
 );
    
    if (state.timeline.updateClip(clipId, updated)) {
      _loadClips();
    }
  }
  
  // NEW: Explicitly push state after move completes (called from timeline widget)
  void commitClipMove() {
    state.timeline.pushState();
  }

  void changeClipTrack(int clipId, int newTrackId) {
    try {
 final clip = state.clips.firstWhere((c) => c.clipId == clipId);
      
      // Validate target track type - STRICT validation
      final targetTrack = state.tracks.firstWhere(
      (t) => t.trackId == newTrackId,
     orElse: () => TrackData(
    trackId: -1,
    trackType: TrackType.video,
 trackName: '',
      displayOrder: 0,
    isLocked: false,
     isVisible: true,
  opacity: 1.0,
        ),
      );
      
      if (targetTrack.trackId == -1) {
     debugPrint('Target track not found');
   return;
      }
      
      // Enforce track type rules - must match exactly
  if (targetTrack.trackType == TrackType.text) {
    debugPrint('Cannot move media clip to TEXT track');
  return;
    }
      
if (targetTrack.trackType == TrackType.audio && !clip.isAudioOnly) {
      debugPrint('Cannot move video clip to AUDIO track');
   return;
      }
      
    if (targetTrack.trackType == TrackType.video && clip.isAudioOnly) {
        debugPrint('Cannot move audio clip to VIDEO track');
   return;
      }
      
 final updatedClip = clip.copyWith(trackIndex: newTrackId);
    if (state.timeline.updateClip(clipId, updatedClip)) {
  _loadClips();
 }
    } catch (e) {
  if (kDebugMode) debugPrint('Change track error: $e');
    }
  }

  void trimClipStart(int clipId, int deltaMs) {
    try {
      final clip = state.clips.firstWhere((c) => c.clipId == clipId);
    final newTrimStart = (clip.trimStartMs + deltaMs).clamp(0, clip.trimEndMs - 100);
      
      if (state.timeline.trimClip(clipId, newTrimStart, clip.trimEndMs)) {
        _loadClips();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Trim start error: $e');
    }
  }

  void trimClipEnd(int clipId, int deltaMs) {
    try {
      final clip = state.clips.firstWhere((c) => c.clipId == clipId);
   final newTrimEnd = (clip.trimEndMs + deltaMs).clamp(clip.trimStartMs + 100, 999999);
      
      if (state.timeline.trimClip(clipId, clip.trimStartMs, newTrimEnd)) {
     _loadClips();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Trim end error: $e');
}
  }

  void setClipTrim(int clipId, int trimStartMs, int trimEndMs) {
    try {
      final clip = state.clips.firstWhere((c) => c.clipId == clipId);
      final originalDuration = state.originalDurations[clipId] ?? clip.trimEndMs;
  
   final clampedStart = trimStartMs.clamp(0, originalDuration - 100);
 final clampedEnd = trimEndMs.clamp(clampedStart + 100, originalDuration);
      
      final trimStartDelta = clampedStart - clip.trimStartMs;
  final newStartTimeMs = clip.startTimeMs + trimStartDelta;
    
      if (state.timeline.trimClip(clipId, clampedStart, clampedEnd)) {
        if (trimStartDelta != 0) {
          final updatedClip = clip.copyWith(
      startTimeMs: newStartTimeMs,
   endTimeMs: newStartTimeMs + (clampedEnd - clampedStart),
            trimStartMs: clampedStart,
         trimEndMs: clampedEnd,
          );
     state.timeline.updateClip(clipId, updatedClip);
        }
        _loadClips();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Set trim error: $e');
    }
  }
  
  @override
  void dispose() {
    _playbackTimer?.cancel();
    _audioManager.dispose();
    super.dispose();
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

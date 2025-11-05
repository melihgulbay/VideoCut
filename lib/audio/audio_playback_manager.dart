import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../native/video_engine_wrapper.dart';

/// Manages real-time audio playback synchronized with timeline
/// Note: Video clips have their audio extracted to separate audio files
/// Only audio-only clips are played back through this manager
class AudioPlaybackManager {
  final List<AudioPlayer> _audioPlayers = [];
  final Map<int, String> _clipFilePaths = {};
  final Map<int, bool> _clipIsAudioOnly = {};
  final Map<int, AudioPlayer> _activeClipPlayers = {};
  bool _isInitialized = false;
  bool _isPlaying = false;
  int _currentTimeMs = 0;
  
  static const int _maxPlayers = 5;

  AudioPlaybackManager() {
    _initialize();
  }

  void _initialize() {
    // Create audio players for audio-only files
    for (int i = 0; i < _maxPlayers; i++) {
      _audioPlayers.add(AudioPlayer());
    }
_isInitialized = true;
  }

  /// Register a clip with its file path for playback
  void registerClip(int clipId, String filepath, {bool isAudioOnly = false}) {
    _clipFilePaths[clipId] = filepath;
    _clipIsAudioOnly[clipId] = isAudioOnly;
  }

  /// Unregister a clip
  void unregisterClip(int clipId) {
    _clipFilePaths.remove(clipId);
    _clipIsAudioOnly.remove(clipId);
    final player = _activeClipPlayers[clipId];
  if (player != null) {
      _activeClipPlayers.remove(clipId);
    }
  }

  /// Start playback at specific time with given clips
  Future<void> play(List<ClipData> activeClips, int startTimeMs) async {
    try {
   debugPrint('AUDIO_MGR: === Starting playback ===');
    debugPrint('AUDIO_MGR: Active clips: ${activeClips.length}, start time: ${startTimeMs}ms');
      
      if (!_isInitialized) {
    debugPrint('AUDIO_MGR: ERROR: Not initialized');
   return;
      }
  
    _isPlaying = true;
    _currentTimeMs = startTimeMs;

    // Stop all current playback
    debugPrint('AUDIO_MGR: Stopping all current playback...');
    await stopAll();
      debugPrint('AUDIO_MGR: All stopped');

    // For each active clip at this time, start its audio
  // ONLY play audio-only clips (video clips are muted, their audio is in separate audio clips)
      final audioOnlyClips = activeClips.where((clip) => clip.isAudioOnly).toList();
      debugPrint('AUDIO_MGR: Filtered to ${audioOnlyClips.length} audio-only clips');
      
      int clipIndex = 0;
  for (final clip in audioOnlyClips) {
   clipIndex++;
        debugPrint('AUDIO_MGR: Processing clip ${clipIndex}/${audioOnlyClips.length}: ID=${clip.clipId}');
        
      final filepath = _clipFilePaths[clip.clipId];
  if (filepath == null) {
        debugPrint('AUDIO_MGR: WARNING: No filepath for clip ${clip.clipId}, skipping');
  continue;
        }

 debugPrint('AUDIO_MGR: Clip ${clip.clipId} filepath: $filepath');
  
   // Calculate offset within the clip
      final clipOffsetMs = startTimeMs - clip.startTimeMs;
   final sourceTimeMs = clip.trimStartMs + (clipOffsetMs * clip.speed).toInt();

 debugPrint('AUDIO_MGR: Clip ${clip.clipId} offset: ${clipOffsetMs}ms, source time: ${sourceTimeMs}ms, speed: ${clip.speed}x');

      // Always use AudioPlayer for audio-only clips
        debugPrint('AUDIO_MGR: Using AudioPlayer for audio-only clip ${clip.clipId}');
      await _playWithAudioPlayer(clip, filepath, sourceTimeMs);
    }
 
      debugPrint('AUDIO_MGR: === Playback started successfully ===');
    } catch (e, stackTrace) {
      debugPrint('AUDIO_MGR: FATAL ERROR in play(): $e');
 debugPrint('AUDIO_MGR: Stack trace: $stackTrace');
    }
  }

  Future<void> _playClipAudio(ClipData clip, String filepath, int startPositionMs, bool isAudioOnly) async {
    try {
      debugPrint('AUDIO_MGR: _playClipAudio for clip ${clip.clipId}, isAudioOnly: $isAudioOnly');
      
 if (isAudioOnly) {
 // Use AudioPlayer for audio-only files (MP3, WAV, etc.)
        debugPrint('AUDIO_MGR: Using AudioPlayer for clip ${clip.clipId}');
        await _playWithAudioPlayer(clip, filepath, startPositionMs);
      } 
    } catch (e, stackTrace) {
    debugPrint('AUDIO_MGR: ERROR playing clip ${clip.clipId} audio: $e');
      debugPrint('AUDIO_MGR: Stack trace: $stackTrace');
    }
  }

  Future<void> _playWithAudioPlayer(ClipData clip, String filepath, int startPositionMs) async {
    try {
      debugPrint('AUDIO_MGR: _playWithAudioPlayer start for clip ${clip.clipId}');
  
 // Find available audio player
AudioPlayer? player;
    for (final p in _audioPlayers) {
      if (p.state != PlayerState.playing) {
     player = p;
 break;
      }
  }
    
 if (player == null) {
 debugPrint('AUDIO_MGR: ERROR: No available audio player');
 return;
    }

      debugPrint('AUDIO_MGR: Found available audio player');
      debugPrint('AUDIO_MGR: Stopping player...');
      await player.stop();
      
      debugPrint('AUDIO_MGR: Setting volume to 1.0...');
    await player.setVolume(1.0);
      
      debugPrint('AUDIO_MGR: Setting playback rate to ${clip.speed}...');
    await player.setPlaybackRate(clip.speed);
    
      debugPrint('AUDIO_MGR: Creating source from: $filepath');
    final source = DeviceFileSource(filepath);
  
      debugPrint('AUDIO_MGR: Starting playback from ${startPositionMs}ms...');
  await player.play(source, position: Duration(milliseconds: startPositionMs));
    
    _activeClipPlayers[clip.clipId] = player;
      debugPrint('AUDIO_MGR: ? AudioPlayer playback started for clip ${clip.clipId}');
    } catch (e, stackTrace) {
      debugPrint('AUDIO_MGR: ERROR in _playWithAudioPlayer for clip ${clip.clipId}: $e');
      debugPrint('AUDIO_MGR: Stack trace: $stackTrace');
 }
  }

  /// Pause all audio playback
  Future<void> pause() async {
  _isPlaying = false;
    for (final player in _activeClipPlayers.values) {
      try {
      await player.pause();
    } catch (e) {
        debugPrint('Error pausing player: $e');
      }
    }
  }

  /// Stop all audio playback
  Future<void> stopAll() async {
    try {
   debugPrint('AUDIO_MGR: stopAll() called');
    _isPlaying = false;
    
    // Stop audio players
      debugPrint('AUDIO_MGR: Stopping ${_audioPlayers.length} audio players...');
  for (final player in _audioPlayers) {
  try {
  await player.stop();
      } catch (e) {
     debugPrint('AUDIO_MGR: Error stopping audio player: $e');
      }
    }
    
    _activeClipPlayers.clear();
    debugPrint('AUDIO_MGR: stopAll() complete');
    } catch (e, stackTrace) {
      debugPrint('AUDIO_MGR: ERROR in stopAll(): $e');
  debugPrint('AUDIO_MGR: Stack trace: $stackTrace');
    }
  }

  /// Seek to a specific time (stops playback)
  Future<void> seek(int timeMs) async {
    _currentTimeMs = timeMs;
await stopAll();
  }

  /// Dispose all resources
  Future<void> dispose() async {
    await stopAll();
    
    for (final player in _audioPlayers) {
      try {
        await player.dispose();
      } catch (e) {
   debugPrint('Error disposing audio player: $e');
    }
    }
    
    _audioPlayers.clear();
    _clipFilePaths.clear();
 _clipIsAudioOnly.clear();
    _activeClipPlayers.clear();
    _isInitialized = false;
  }

  bool get isPlaying => _isPlaying;
  int get currentTimeMs => _currentTimeMs;
}

#include "api.h"
#include "video_engine.h"
#include "audio_engine.h"
#include "timeline.h"
#include "exporter.h"
#include <new>
#include <iostream>

using namespace videocut;

// Initialize FFmpeg
void videocut_initialize() {
    // Modern FFmpeg doesn't require av_register_all()
}

void videocut_cleanup() {
    // Cleanup if needed
}

// Timeline operations
TimelineHandle timeline_create() {
    try {
        return new Timeline();
    } catch (std::bad_alloc&) {
    return nullptr;
    }
}

void timeline_destroy(TimelineHandle handle) {
    if (handle) {
        delete static_cast<Timeline*>(handle);
    }
}

// Track management
int timeline_add_track(TimelineHandle handle, int track_type, const char* name) {
    if (!handle) return -1;
    Timeline* timeline = static_cast<Timeline*>(handle);
    return timeline->addTrack(static_cast<TrackType>(track_type), name);
}

int timeline_remove_track(TimelineHandle handle, int track_id) {
    if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->removeTrack(track_id));
}

int timeline_swap_tracks(TimelineHandle handle, int track_a, int track_b) {
    if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->swapTracks(track_a, track_b));
}

int timeline_get_track_info(TimelineHandle handle, int track_id, TrackInfo* info) {
    if (!handle || !info) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->getTrackInfo(track_id, info));
}

int timeline_get_track_count(TimelineHandle handle) {
    if (!handle) return 0;
    Timeline* timeline = static_cast<Timeline*>(handle);
  return timeline->getTrackCount();
}

int timeline_get_all_tracks(TimelineHandle handle, TrackInfo* tracks, int max_count) {
    if (!handle || !tracks) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->getAllTracks(tracks, max_count));
}

int timeline_add_clip(TimelineHandle handle, const char* filepath, 
    int track_index, int64_t start_time_ms) {
    if (!handle) return -1;
    Timeline* timeline = static_cast<Timeline*>(handle);
    return timeline->addClip(filepath, track_index, start_time_ms);
}

int timeline_remove_clip(TimelineHandle handle, int clip_id) {
    if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
  Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->removeClip(clip_id));
}

int timeline_update_clip(TimelineHandle handle, int clip_id, const ClipInfo* info) {
    if (!handle || !info) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
 return static_cast<int>(timeline->updateClip(clip_id, info));
}

int timeline_get_clip(TimelineHandle handle, int clip_id, ClipInfo* info) {
  if (!handle || !info) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
  Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->getClip(clip_id, info));
}

int timeline_get_all_clips(TimelineHandle handle, ClipInfo* clips, int max_count) {
    if (!handle || !clips) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->getAllClips(clips, max_count));
}

int timeline_get_clip_count(TimelineHandle handle) {
    if (!handle) return 0;
    Timeline* timeline = static_cast<Timeline*>(handle);
  return timeline->getClipCount();
}

// Timeline editing
int timeline_split_clip(TimelineHandle handle, int clip_id, 
    int64_t split_time_ms, int* new_clip_id) {
    if (!handle || !new_clip_id) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->splitClip(clip_id, split_time_ms, new_clip_id));
}

int timeline_trim_clip(TimelineHandle handle, int clip_id, 
            int64_t trim_start_ms, int64_t trim_end_ms) {
 if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->trimClip(clip_id, trim_start_ms, trim_end_ms));
}

int timeline_set_clip_speed(TimelineHandle handle, int clip_id, double speed) {
    if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->setClipSpeed(clip_id, speed));
}

int timeline_set_clip_volume(TimelineHandle handle, int clip_id, float volume) {
    if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->setClipVolume(clip_id, volume));
}

int timeline_mute_clip(TimelineHandle handle, int clip_id, int muted) {
    if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    auto* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->muteClip(clip_id, muted != 0));
}

int timeline_set_clip_scale(TimelineHandle handle, int clip_id, float scale_x, float scale_y) {
    if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    auto* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->setClipScale(clip_id, scale_x, scale_y));
}

int timeline_set_clip_aspect_lock(TimelineHandle handle, int clip_id, int locked) {
 if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    auto* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->setClipAspectLock(clip_id, locked != 0));
}

// NEW: Text layer API implementations
int timeline_add_text_layer(TimelineHandle handle, const videocut::TextLayer* layer) {
    if (!handle || !layer) return -1;
    Timeline* timeline = static_cast<Timeline*>(handle);
    return timeline->addTextLayer(layer);
}

int timeline_remove_text_layer(TimelineHandle handle, int layer_id) {
    if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->removeTextLayer(layer_id));
}

int timeline_update_text_layer(TimelineHandle handle, int layer_id, const videocut::TextLayer* layer) {
    if (!handle || !layer) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->updateTextLayer(layer_id, layer));
}

int timeline_get_text_layer_count(TimelineHandle handle) {
    if (!handle) return 0;
    Timeline* timeline = static_cast<Timeline*>(handle);
    return timeline->getTextLayerCount();
}

int timeline_get_all_text_layers(TimelineHandle handle, videocut::TextLayer* layers, int max_count) {
    if (!handle || !layers) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->getAllTextLayers(layers, max_count));
}

// Playback
int timeline_render_frame(TimelineHandle handle, int64_t timestamp_ms, videocut::FrameData* frame) {
 if (!handle || !frame) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
  Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->renderFrameAt(timestamp_ms, frame));
}

int timeline_render_frame_ex(TimelineHandle handle, int64_t timestamp_ms, videocut::FrameData* frame, const videocut::RenderSettings* settings) {
 if (!handle || !frame || !settings) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
 Timeline* timeline = static_cast<Timeline*>(handle);
 // The timeline compositor will respect RenderSettings where applicable. For now, we allocate target frame buffer if requested.
 frame->width = settings->width;
 frame->height = settings->height;
 int rgba_size = frame->width * frame->height *4;
 frame->data = new uint8_t[rgba_size];
 std::fill(frame->data, frame->data + rgba_size,0);
 // Call timeline render but provide settings through a new API on Timeline if needed. For minimal change, we'll set a global or pass via thread-local in future. For now, Timeline will detect frame size from frame->width/height.
 return static_cast<int>(timeline->renderFrameAt(timestamp_ms, frame));
}

void timeline_release_frame(FrameData* frame) {
    if (frame && frame->data) {
   delete[] frame->data;
     frame->data = nullptr;
    }
}

int64_t timeline_get_duration(TimelineHandle handle) {
    if (!handle) return 0;
    Timeline* timeline = static_cast<Timeline*>(handle);
  return timeline->getTotalDuration();
}

// Undo/Redo
void timeline_push_state(TimelineHandle handle) {
    if (!handle) return;
  Timeline* timeline = static_cast<Timeline*>(handle);
    timeline->pushState();
}

int timeline_can_undo(TimelineHandle handle) {
  if (!handle) return 0;
  Timeline* timeline = static_cast<Timeline*>(handle);
    return timeline->canUndo() ? 1 : 0;
}

int timeline_can_redo(TimelineHandle handle) {
  if (!handle) return 0;
  Timeline* timeline = static_cast<Timeline*>(handle);
  return timeline->canRedo() ? 1 : 0;
}

int timeline_undo(TimelineHandle handle) {
    if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Timeline* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->undo());
}

int timeline_redo(TimelineHandle handle) {
    if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    auto* timeline = static_cast<Timeline*>(handle);
    return static_cast<int>(timeline->redo());
}

void timeline_clear_history(TimelineHandle handle) {
    if (!handle) return;
    auto* timeline = static_cast<Timeline*>(handle);
    timeline->clearHistory();
}

int video_get_metadata(const char* filepath, VideoMetadata* metadata) {
 if (!filepath || !metadata) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
 
 VideoEngine engine;
 ErrorCode result = engine.loadVideo(filepath);
 if (result != ErrorCode::SUCCESS) {
 return static_cast<int>(result);
 }
 
 return static_cast<int>(engine.getMetadata(metadata));
}

// Audio waveform
int audio_generate_waveform(const char* filepath, AudioWaveform* waveform, 
 int sample_count) {
 if (!filepath || !waveform) {
 std::cerr << "[C++] audio_generate_waveform: Invalid parameters" << std::endl;
 return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
 }
 
 std::cout << "[C++] audio_generate_waveform: Loading audio from: " << filepath << std::endl;
 
 AudioEngine engine;
 ErrorCode result = engine.loadAudio(filepath);
 
 std::cout << "[C++] audio_generate_waveform: loadAudio returned code: " 
 << static_cast<int>(result) << std::endl;
 
 if (result != ErrorCode::SUCCESS) {
 std::cout << "[C++] audio_generate_waveform: No audio stream found, returning empty waveform" 
 << std::endl;
 waveform->samples = nullptr;
 waveform->sample_count =0;
 waveform->channels =0;
 return static_cast<int>(ErrorCode::SUCCESS); // Return success but empty data
 }
 
 std::cout << "[C++] audio_generate_waveform: Generating waveform with " 
 << sample_count << " samples" << std::endl;
 
 ErrorCode waveform_result = engine.generateWaveform(waveform, sample_count);
 
 std::cout << "[C++] audio_generate_waveform: generateWaveform returned code: " 
 << static_cast<int>(waveform_result) << std::endl;
 
 if (waveform_result == ErrorCode::SUCCESS && waveform->samples) {
 std::cout << "[C++] audio_generate_waveform: Successfully generated waveform with " 
 << waveform->sample_count << " samples" << std::endl;
 }
 
 return static_cast<int>(waveform_result);
}

void audio_release_waveform(AudioWaveform* waveform) {
 if (waveform && waveform->samples) {
 std::cout << "[C++] audio_release_waveform: Releasing waveform" << std::endl;
 delete[] waveform->samples;
 waveform->samples = nullptr;
 }
}

// Export
ExporterHandle exporter_create() {
    try {
        return new Exporter();
    } catch (std::bad_alloc&) {
     return nullptr;
    }
}

void exporter_destroy(ExporterHandle handle) {
    if (handle) {
        delete static_cast<Exporter*>(handle);
    }
}

int exporter_start(ExporterHandle handle, TimelineHandle timeline, 
 const ExportSettings* settings) {
    if (!handle || !timeline || !settings) {
 return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    }
    
    Exporter* exporter = static_cast<Exporter*>(handle);
    Timeline* tl = static_cast<Timeline*>(timeline);
  return static_cast<int>(exporter->startExport(tl, settings));
}

int exporter_get_progress(ExporterHandle handle, float* progress) {
    if (!handle || !progress) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    Exporter* exporter = static_cast<Exporter*>(handle);
    return static_cast<int>(exporter->getProgress(progress));
}

int exporter_cancel(ExporterHandle handle) {
    if (!handle) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
 Exporter* exporter = static_cast<Exporter*>(handle);
 return static_cast<int>(exporter->cancelExport());
}

int exporter_is_exporting(ExporterHandle handle) {
 if (!handle) return 0;
  Exporter* exporter = static_cast<Exporter*>(handle);
  return exporter->isExporting() ? 1 : 0;
}

// NEW: Check if file is audio-only
int audio_is_audio_only(const char* filepath) {
    if (!filepath) return 0;
    
    AudioEngine engine;
    if (engine.loadAudio(filepath) != ErrorCode::SUCCESS) {
        return 0;
    }
    
  return engine.isAudioOnly() ? 1 : 0;
}

// NEW: Get audio file metadata  
int audio_get_metadata(const char* filepath, int64_t* duration_ms,
     int* channels, int* sample_rate) {
    if (!filepath) return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
  
    AudioEngine engine;
  ErrorCode result = engine.loadAudio(filepath);
    if (result != ErrorCode::SUCCESS) {
        return static_cast<int>(result);
 }
    
    return static_cast<int>(engine.getAudioMetadata(duration_ms, channels, sample_rate));
}

// NEW: Extract audio from video to MP3
int video_extract_audio(const char* video_path, const char* output_mp3_path) {
    if (!video_path || !output_mp3_path) {
        return static_cast<int>(ErrorCode::ERROR_INVALID_PARAMETER);
    }

    VideoEngine engine;
    ErrorCode result = engine.loadVideo(video_path);
    if (result != ErrorCode::SUCCESS) {
        return static_cast<int>(result);
    }

    result = engine.extractAudioToFile(output_mp3_path);
    engine.closeVideo();
    
    return static_cast<int>(result);
}

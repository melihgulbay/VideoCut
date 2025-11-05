#ifndef VIDEOCUT_API_H
#define VIDEOCUT_API_H

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

// Platform export
#if defined(_WIN32)
    #define EXPORT __declspec(dllexport)
#else
 #define EXPORT __attribute__((visibility("default")))
#endif

// Timeline handle
typedef void* TimelineHandle;
typedef void* ExporterHandle;

// Initialize/cleanup
EXPORT void videocut_initialize();
EXPORT void videocut_cleanup();

// Timeline operations
EXPORT TimelineHandle timeline_create();
EXPORT void timeline_destroy(TimelineHandle handle);

// NEW: Track management
EXPORT int timeline_add_track(TimelineHandle handle, int track_type, const char* name);
EXPORT int timeline_remove_track(TimelineHandle handle, int track_id);
EXPORT int timeline_swap_tracks(TimelineHandle handle, int track_a, int track_b);
EXPORT int timeline_get_track_info(TimelineHandle handle, int track_id, videocut::TrackInfo* info);
EXPORT int timeline_get_track_count(TimelineHandle handle);
EXPORT int timeline_get_all_tracks(TimelineHandle handle, videocut::TrackInfo* tracks, int max_count);

EXPORT int timeline_add_clip(TimelineHandle handle, const char* filepath, 
          int track_index, int64_t start_time_ms);
EXPORT int timeline_remove_clip(TimelineHandle handle, int clip_id);
EXPORT int timeline_update_clip(TimelineHandle handle, int clip_id, const videocut::ClipInfo* info);
EXPORT int timeline_get_clip(TimelineHandle handle, int clip_id, videocut::ClipInfo* info);
EXPORT int timeline_get_all_clips(TimelineHandle handle, videocut::ClipInfo* clips, int max_count);
EXPORT int timeline_get_clip_count(TimelineHandle handle);

// Timeline editing
EXPORT int timeline_split_clip(TimelineHandle handle, int clip_id, 
            int64_t split_time_ms, int* new_clip_id);
EXPORT int timeline_trim_clip(TimelineHandle handle, int clip_id, 
    int64_t trim_start_ms, int64_t trim_end_ms);
EXPORT int timeline_set_clip_speed(TimelineHandle handle, int clip_id, double speed);
EXPORT int timeline_set_clip_volume(TimelineHandle handle, int clip_id, float volume);
EXPORT int timeline_mute_clip(TimelineHandle handle, int clip_id, int muted);

// NEW: Scale operations
EXPORT int timeline_set_clip_scale(TimelineHandle handle, int clip_id, float scale_x, float scale_y);
EXPORT int timeline_set_clip_aspect_lock(TimelineHandle handle, int clip_id, int locked);

// NEW: Text layer operations
EXPORT int timeline_add_text_layer(TimelineHandle handle, const videocut::TextLayer* layer);
EXPORT int timeline_remove_text_layer(TimelineHandle handle, int layer_id);
EXPORT int timeline_update_text_layer(TimelineHandle handle, int layer_id, const videocut::TextLayer* layer);
EXPORT int timeline_get_text_layer_count(TimelineHandle handle);
EXPORT int timeline_get_all_text_layers(TimelineHandle handle, videocut::TextLayer* layers, int max_count);

// Playback
EXPORT int timeline_render_frame(TimelineHandle handle, int64_t timestamp_ms, videocut::FrameData* frame);
// NEW: extended render with explicit RenderSettings
EXPORT int timeline_render_frame_ex(TimelineHandle handle, int64_t timestamp_ms, videocut::FrameData* frame, const videocut::RenderSettings* settings);
EXPORT void timeline_release_frame(videocut::FrameData* frame);
EXPORT int64_t timeline_get_duration(TimelineHandle handle);

// Undo/Redo
EXPORT void timeline_push_state(TimelineHandle handle);
EXPORT int timeline_can_undo(TimelineHandle handle);
EXPORT int timeline_can_redo(TimelineHandle handle);
EXPORT int timeline_undo(TimelineHandle handle);
EXPORT int timeline_redo(TimelineHandle handle);
EXPORT void timeline_clear_history(TimelineHandle handle); // NEW: Clear undo/redo history

// Video metadata
EXPORT int video_get_metadata(const char* filepath, videocut::VideoMetadata* metadata);

// Audio waveform
EXPORT int audio_generate_waveform(const char* filepath, videocut::AudioWaveform* waveform, 
             int sample_count);
EXPORT void audio_release_waveform(videocut::AudioWaveform* waveform);

// Export
EXPORT ExporterHandle exporter_create();
EXPORT void exporter_destroy(ExporterHandle handle);
EXPORT int exporter_start(ExporterHandle handle, TimelineHandle timeline, 
  const videocut::ExportSettings* settings);
EXPORT int exporter_get_progress(ExporterHandle handle, float* progress);
EXPORT int exporter_cancel(ExporterHandle handle);
EXPORT int exporter_is_exporting(ExporterHandle handle);

// NEW: Audio-only file detection
EXPORT int audio_is_audio_only(const char* filepath);

// NEW: Get audio file metadata
EXPORT int audio_get_metadata(const char* filepath, int64_t* duration_ms, 
           int* channels, int* sample_rate);

// NEW: Extract audio from video file to MP3
EXPORT int video_extract_audio(const char* video_path, const char* output_mp3_path);

#ifdef __cplusplus
}
#endif

#endif // VIDEOCUT_API_H

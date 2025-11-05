#ifndef VIDEOCUT_TIMELINE_H
#define VIDEOCUT_TIMELINE_H

#include "types.h"
#include "video_engine.h"
#include "audio_engine.h"
#include <map>
#include <vector>
#include <memory>
#include <string>

namespace videocut {

struct TimelineClip {
    int clip_id;
 std::string filepath;
    ClipInfo info;
    std::shared_ptr<VideoEngine> video_engine;
    std::shared_ptr<AudioEngine> audio_engine;
    bool is_audio_only;
  
    TimelineClip() : clip_id(-1), is_audio_only(false) {}
};

// NEW: Complete timeline state for undo/redo
struct TimelineState {
    std::map<int, TimelineClip> clips;
    std::map<int, TextLayer> text_layers;
    std::map<int, TrackInfo> tracks;
    int next_clip_id;
 int next_text_layer_id;
    int next_track_id;
    
    TimelineState() : next_clip_id(1), next_text_layer_id(1), next_track_id(1) {}
};

class Timeline {
public:
    Timeline();
    ~Timeline();
    
    // Track management
    int addTrack(TrackType type, const char* name = nullptr);
    ErrorCode removeTrack(int track_id);
ErrorCode swapTracks(int track_a, int track_b);
 ErrorCode getTrackInfo(int track_id, TrackInfo* info);
    int getTrackCount();
    ErrorCode getAllTracks(TrackInfo* tracks, int max_count);
    
    // Clip management
    int addClip(const char* filepath, int track_index, int64_t start_time_ms);
    ErrorCode removeClip(int clip_id);
    ErrorCode updateClip(int clip_id, const ClipInfo* info);
    ErrorCode getClip(int clip_id, ClipInfo* info);
    int getClipCount();
    ErrorCode getAllClips(ClipInfo* clips, int max_count);
    
    // Clip operations
    ErrorCode splitClip(int clip_id, int64_t split_time_ms, int* new_clip_id);
  ErrorCode trimClip(int clip_id, int64_t trim_start_ms, int64_t trim_end_ms);
    ErrorCode setClipSpeed(int clip_id, double speed);
    ErrorCode setClipVolume(int clip_id, float volume);
    ErrorCode muteClip(int clip_id, bool muted);
    ErrorCode setClipScale(int clip_id, float scale_x, float scale_y);
    ErrorCode setClipAspectLock(int clip_id, bool locked);
    
  // Text layer management
    int addTextLayer(const TextLayer* layer);
    ErrorCode removeTextLayer(int layer_id);
    ErrorCode updateTextLayer(int layer_id, const TextLayer* layer);
    int getTextLayerCount();
    ErrorCode getAllTextLayers(TextLayer* layers, int max_count);
    
    // Rendering
    ErrorCode renderFrameAt(int64_t timestamp_ms, FrameData* frame);
    ErrorCode renderFrameAt(int64_t timestamp_ms, FrameData* frame, const RenderSettings* settings);
    int64_t getTotalDuration();
    
    // Undo/Redo - NEW: Complete state management
    void pushState();
    bool canUndo();
    bool canRedo();
    ErrorCode undo();
    ErrorCode redo();
    void clearHistory(); // NEW: Clear undo/redo stacks
    
    std::shared_ptr<AudioEngine> getAudioEngineForClip(int clip_id);
    
private:
    std::map<int, TimelineClip> clips_;
    std::map<int, TextLayer> text_layers_;
    std::map<int, TrackInfo> tracks_;
    
    int next_clip_id_;
    int next_text_layer_id_;
    int next_track_id_;
    
    // NEW: Complete state snapshots for undo/redo
    std::vector<TimelineState> undo_stack_;
    std::vector<TimelineState> redo_stack_;
    static const size_t max_history_ = 50;
  
    // Caching for performance
    int last_rendered_clip_id_;
    int64_t last_rendered_source_time_ms_;
    
    void updateAllTrackDisplayOrders();
    
    ErrorCode compositeFrames(int64_t timestamp_ms, 
    const std::vector<TimelineClip*>& active_clips, 
         FrameData* result);
    ErrorCode compositeFrames(int64_t timestamp_ms, 
           const std::vector<TimelineClip*>& active_clips, 
  FrameData* result,
          const RenderSettings* settings);
 
    // NEW: State snapshot helpers
    TimelineState captureState() const;
    void restoreState(const TimelineState& state);
};

} // namespace videocut

#endif // VIDEOCUT_TIMELINE_H

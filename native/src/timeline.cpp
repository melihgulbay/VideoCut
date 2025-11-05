#include "timeline.h"
#include "renderer.h"
#include "simple_text_renderer.h"
#include <algorithm>
#include <iostream>

namespace videocut {

Timeline::Timeline() : next_clip_id_(1), next_text_layer_id_(1), next_track_id_(1) {
 last_rendered_clip_id_ = -1;
 last_rendered_source_time_ms_ = -1;
 
 // Start with zero tracks - user will add them as needed
 // Tracks will be auto-created when importing media
}

Timeline::~Timeline() {
}

// Track management - STABLE DISPLAY ORDER WITH NO CONFLICTS
int Timeline::addTrack(TrackType type, const char* name) {
TrackInfo track;
  track.track_id = next_track_id_++;
  track.track_type = type;
    
    // Set track name
    if (name) {
    strncpy(track.track_name, name, sizeof(track.track_name) - 1);
track.track_name[sizeof(track.track_name) - 1] = '\0';
    } else {
   // Count existing tracks of this type for proper numbering
        int type_count = 0;
  for (const auto& pair : tracks_) {
            if (pair.second.track_type == type) {
type_count++;
    }
 }
        
   const char* type_name = "";
  switch (type) {
  case TrackType::TEXT: type_name = "Text"; break;
    case TrackType::VIDEO: type_name = "Video"; break;
   case TrackType::AUDIO: type_name = "Audio"; break;
      case TrackType::OVERLAY: type_name = "Overlay"; break;
  }
  snprintf(track.track_name, sizeof(track.track_name), "%s %d", type_name, type_count + 1);
    }
    
    // NEW APPROACH: Recalculate ALL track display orders to maintain proper order
    // Collect all tracks by type
    std::vector<int> text_track_ids, video_track_ids, audio_track_ids;
    
    for (const auto& pair : tracks_) {
        switch (pair.second.track_type) {
      case TrackType::TEXT:
   case TrackType::OVERLAY:
       text_track_ids.push_back(pair.first);
       break;
   case TrackType::VIDEO:
                video_track_ids.push_back(pair.first);
            break;
   case TrackType::AUDIO:
        audio_track_ids.push_back(pair.first);
        break;
        }
    }
    
    // Add the new track ID to appropriate list
    switch (type) {
        case TrackType::TEXT:
 case TrackType::OVERLAY:
        text_track_ids.push_back(track.track_id);
            break;
  case TrackType::VIDEO:
    video_track_ids.push_back(track.track_id);
       break;
        case TrackType::AUDIO:
          audio_track_ids.push_back(track.track_id);
     break;
    }
    
    // Sort each group by track ID for predictable order
    std::sort(text_track_ids.begin(), text_track_ids.end());
    std::sort(video_track_ids.begin(), video_track_ids.end());
    std::sort(audio_track_ids.begin(), audio_track_ids.end());
    
    // Store track BEFORE assigning display orders
    tracks_[track.track_id] = track;
    
    // Assign display orders: TEXT first, VIDEO second, AUDIO last
    int display_order = 0;
  
    for (int id : text_track_ids) {
   tracks_[id].display_order = display_order++;
    }
    for (int id : video_track_ids) {
        tracks_[id].display_order = display_order++;
 }
    for (int id : audio_track_ids) {
 tracks_[id].display_order = display_order++;
 }
    
    std::cout << "[C++] Added track: ID=" << track.track_id 
    << " Type=" << static_cast<int>(type)
      << " DisplayOrder=" << tracks_[track.track_id].display_order
      << " Name=" << tracks_[track.track_id].track_name << std::endl;
    
    pushState(); // Add pushState for undo/redo
    return track.track_id;
}

void Timeline::updateAllTrackDisplayOrders() {
    // This function is NO LONGER USED
    // Display orders are now STABLE and assigned only once at creation
    // Keeping it for compatibility but it does nothing
}

ErrorCode Timeline::removeTrack(int track_id) {
    auto it = tracks_.find(track_id);
    if (it == tracks_.end()) {
 return ErrorCode::ERROR_INVALID_PARAMETER;
    }
 
    // Check if track has any clips
    for (const auto& pair : clips_) {
      if (pair.second.info.track_index == track_id) {
    return ErrorCode::ERROR_INVALID_PARAMETER;  // Cannot delete track with clips
      }
    }
    
 // Check if track has any text layers
    for (const auto& pair : text_layers_) {
        if (pair.second.track_index == track_id) {
     return ErrorCode::ERROR_INVALID_PARAMETER;  // Cannot delete track with text
        }
    }
    
    tracks_.erase(it);
  
    // NO LONGER recalculate display orders - they are stable
    
    pushState(); // NEW: Add pushState for undo/redo
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::swapTracks(int track_a, int track_b) {
    auto it_a = tracks_.find(track_a);
    auto it_b = tracks_.find(track_b);
    
    if (it_a == tracks_.end() || it_b == tracks_.end()) {
    return ErrorCode::ERROR_INVALID_PARAMETER;
    }
    
 // Simply swap display orders
    std::swap(it_a->second.display_order, it_b->second.display_order);
    
    // Note: Track IDs and clip references remain unchanged
    // Only visual display order changes
 
    pushState(); // NEW: Add pushState for undo/redo
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::getTrackInfo(int track_id, TrackInfo* info) {
    auto it = tracks_.find(track_id);
    if (it == tracks_.end()) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }
    
    *info = it->second;
    return ErrorCode::SUCCESS;
}

int Timeline::getTrackCount() {
  return static_cast<int>(tracks_.size());
}

ErrorCode Timeline::getAllTracks(TrackInfo* tracks, int max_count) {
    int i = 0;
    for (const auto& pair : tracks_) {
        if (i >= max_count) break;
        tracks[i++] = pair.second;
    }
    return ErrorCode::SUCCESS;
}

int Timeline::addClip(const char* filepath, int track_index, int64_t start_time_ms) {
    if (!filepath) {
        return -1;
    }

    // Load the media first to determine its type
    TimelineClip clip;
clip.clip_id = next_clip_id_++;
    clip.filepath = filepath;
    clip.info.clip_id = clip.clip_id;
    clip.info.start_time_ms = start_time_ms;
 clip.info.track_index = track_index;
    clip.info.trim_start_ms = 0;
    clip.info.speed = 1.0;
    clip.info.volume = 1.0f;
    clip.info.is_muted = false;

    strncpy(clip.info.filepath, filepath, sizeof(clip.info.filepath) - 1);
    clip.info.filepath[sizeof(clip.info.filepath) - 1] = '\0';

    // Try loading as video first
    clip.video_engine = std::make_shared<VideoEngine>();
  if (clip.video_engine->loadVideo(filepath) == ErrorCode::SUCCESS) {
        clip.is_audio_only = false;
        clip.info.clip_type = ClipType::VIDEO;
        clip.info.trim_end_ms = clip.video_engine->getDuration();
        clip.info.end_time_ms = start_time_ms + clip.info.trim_end_ms;
   clip.info.duration_ms = clip.info.trim_end_ms;
    } else {
        // Try as audio
        clip.video_engine = nullptr;
     clip.audio_engine = std::make_shared<AudioEngine>();
        if (clip.audio_engine->loadAudio(filepath) == ErrorCode::SUCCESS) {
            clip.is_audio_only = true;
            clip.info.clip_type = ClipType::AUDIO_ONLY;
     
         int64_t duration_ms = 0;
          if (clip.audio_engine->getAudioMetadata(&duration_ms, nullptr, nullptr) == ErrorCode::SUCCESS) {
         clip.info.trim_end_ms = duration_ms;
 clip.info.duration_ms = duration_ms;
            } else {
           clip.info.trim_end_ms = 60000;
       clip.info.duration_ms = 60000;
      }
   clip.info.end_time_ms = start_time_ms + clip.info.trim_end_ms;
        } else {
        return -1;  // Failed to load
  }
    }

    // STRICT VALIDATION: Check track type compatibility
 auto track_it = tracks_.find(track_index);
    if (track_it != tracks_.end()) {
TrackType track_type = track_it->second.track_type;
        
        // TEXT/OVERLAY tracks: No media clips allowed
      if (track_type == TrackType::TEXT || track_type == TrackType::OVERLAY) {
    return -1;
      }
   
        // VIDEO tracks: Only video clips allowed
        if (track_type == TrackType::VIDEO && clip.is_audio_only) {
       return -1;
  }
        
   // AUDIO tracks: Only audio clips allowed
        if (track_type == TrackType::AUDIO && !clip.is_audio_only) {
            return -1;
 }
    }

    clips_[clip.clip_id] = clip;
    pushState();
    
  return clip.clip_id;
}

ErrorCode Timeline::removeClip(int clip_id) {
auto it = clips_.find(clip_id);
    if (it == clips_.end()) {
  return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    clips_.erase(it);
    pushState();
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::updateClip(int clip_id, const ClipInfo* info) {
  auto it = clips_.find(clip_id);
    if (it == clips_.end()) {
   return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    // Validate track type if track is being changed
    if (info->track_index != it->second.info.track_index) {
        auto track_it = tracks_.find(info->track_index);
        if (track_it != tracks_.end()) {
    TrackType track_type = track_it->second.track_type;
       bool is_audio_only = it->second.is_audio_only;
  
      // TEXT/OVERLAY tracks: No media clips
      if (track_type == TrackType::TEXT || track_type == TrackType::OVERLAY) {
      return ErrorCode::ERROR_INVALID_PARAMETER;
          }
        
// VIDEO tracks: Only video clips
     if (track_type == TrackType::VIDEO && is_audio_only) {
   return ErrorCode::ERROR_INVALID_PARAMETER;
     }
        
      // AUDIO tracks: Only audio clips
 if (track_type == TrackType::AUDIO && !is_audio_only) {
    return ErrorCode::ERROR_INVALID_PARAMETER;
          }
    }
    }

    it->second.info = *info;
    // REMOVED: pushState() - Let caller decide when to push state
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::getClip(int clip_id, ClipInfo* info) {
    auto it = clips_.find(clip_id);
    if (it == clips_.end()) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    *info = it->second.info;
    return ErrorCode::SUCCESS;
}

int Timeline::getClipCount() {
    return clips_.size();
}

ErrorCode Timeline::getAllClips(ClipInfo* clips, int max_count) {
    int i = 0;
    for (const auto& pair : clips_) {
        if (i >= max_count) break;
        clips[i++] = pair.second.info;
    }
    return ErrorCode::SUCCESS;
}

std::shared_ptr<AudioEngine> Timeline::getAudioEngineForClip(int clip_id) {
    auto it = clips_.find(clip_id);
    if (it == clips_.end()) return nullptr;
    return it->second.audio_engine;
}

ErrorCode Timeline::splitClip(int clip_id, int64_t split_time_ms, int* new_clip_id) {
    auto it = clips_.find(clip_id);
    if (it == clips_.end()) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    TimelineClip& original = it->second;
    
    if (split_time_ms <= original.info.start_time_ms || 
        split_time_ms >= original.info.end_time_ms) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
  }

    TimelineClip new_clip = original;
    new_clip.clip_id = next_clip_id_++;
    new_clip.info.clip_id = new_clip.clip_id;
    
  int64_t split_offset = split_time_ms - original.info.start_time_ms;
    new_clip.info.start_time_ms = split_time_ms;
    new_clip.info.trim_start_ms = original.info.trim_start_ms + split_offset;
    
    original.info.end_time_ms = split_time_ms;
    original.info.trim_end_ms = original.info.trim_start_ms + split_offset;

    clips_[new_clip.clip_id] = new_clip;
    *new_clip_id = new_clip.clip_id;
    
    pushState();
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::trimClip(int clip_id, int64_t trim_start_ms, int64_t trim_end_ms) {
    auto it = clips_.find(clip_id);
    if (it == clips_.end()) {
return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    TimelineClip& clip = it->second;
    clip.info.trim_start_ms = trim_start_ms;
  clip.info.trim_end_ms = trim_end_ms;
    
    int64_t duration = trim_end_ms - trim_start_ms;
    clip.info.end_time_ms = clip.info.start_time_ms + duration;

    pushState();
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::setClipSpeed(int clip_id, double speed) {
    auto it = clips_.find(clip_id);
    if (it == clips_.end()) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    it->second.info.speed = speed;
    pushState();
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::setClipVolume(int clip_id, float volume) {
    auto it = clips_.find(clip_id);
  if (it == clips_.end()) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    it->second.info.volume = volume;
    pushState();
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::muteClip(int clip_id, bool muted) {
    auto it = clips_.find(clip_id);
    if (it == clips_.end()) {
      return ErrorCode::ERROR_INVALID_PARAMETER;
    }
    
    it->second.info.is_muted = muted;
    pushState(); // NEW: Add pushState for undo/redo
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::setClipScale(int clip_id, float scale_x, float scale_y) {
    auto it = clips_.find(clip_id);
    if (it == clips_.end()) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }
    
    // Clamp scale values to reasonable range (1% to 500%)
    it->second.info.scale_x = std::clamp(scale_x, 0.01f, 5.0f);
    it->second.info.scale_y = std::clamp(scale_y, 0.01f, 5.0f);
    
    pushState(); // NEW: Add pushState for undo/redo
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::setClipAspectLock(int clip_id, bool locked) {
    auto it = clips_.find(clip_id);
    if (it == clips_.end()) {
   return ErrorCode::ERROR_INVALID_PARAMETER;
  }
    
    it->second.info.lock_aspect_ratio = locked;
    
    // If locking, set both scales to average
    if (locked) {
      float avg_scale = (it->second.info.scale_x + it->second.info.scale_y) / 2.0f;
        it->second.info.scale_x = avg_scale;
     it->second.info.scale_y = avg_scale;
    }
    
    pushState(); // NEW: Add pushState for undo/redo
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::renderFrameAt(int64_t timestamp_ms, FrameData* frame) {
    return renderFrameAt(timestamp_ms, frame, nullptr);
}

ErrorCode Timeline::renderFrameAt(int64_t timestamp_ms, FrameData* frame, const RenderSettings* settings) {
  std::vector<TimelineClip*> active_clips;
    
    for (auto& pair : clips_) {
 TimelineClip& clip = pair.second;
   if (timestamp_ms >= clip.info.start_time_ms && 
    timestamp_ms < clip.info.end_time_ms && 
  !clip.is_audio_only) {
            active_clips.push_back(&clip);
     }
    }

    if (active_clips.empty()) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    // Sort by track index (lower index = bottom layer)
    std::sort(active_clips.begin(), active_clips.end(), 
   [](TimelineClip* a, TimelineClip* b) {
            return a->info.track_index < b->info.track_index;
        });

    ErrorCode result = compositeFrames(timestamp_ms, active_clips, frame, settings);
    
    // Render text layers on top
    if (result == ErrorCode::SUCCESS && frame->data) {
        for (const auto& pair : text_layers_) {
      const TextLayer& layer = pair.second;
      if (timestamp_ms >= layer.start_time_ms && timestamp_ms < layer.end_time_ms) {
      if (settings) {
         SimpleTextRenderer::renderText(layer, frame->data, frame->width, frame->height, *settings);
     } else {
   SimpleTextRenderer::renderText(layer, frame->data, frame->width, frame->height);
     }
     }
        }
    }
    
    return result;
}

ErrorCode Timeline::compositeFrames(int64_t timestamp_ms, 
    const std::vector<TimelineClip*>& active_clips, FrameData* result) {
    return compositeFrames(timestamp_ms, active_clips, result, nullptr);
}

ErrorCode Timeline::compositeFrames(int64_t timestamp_ms, 
    const std::vector<TimelineClip*>& active_clips, FrameData* result, const RenderSettings* settings) {
    if (active_clips.empty()) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    int target_width = settings ? settings->width : 1920;
  int target_height = settings ? settings->height : 1080;

    bool first_clip = true;
  
    for (size_t i = 0; i < active_clips.size(); i++) {
        TimelineClip* clip = active_clips[i];
    
        int64_t clip_offset = timestamp_ms - clip->info.start_time_ms;
 int64_t source_time = clip->info.trim_start_ms + 
  static_cast<int64_t>(clip_offset * clip->info.speed);
        
        if (!clip->video_engine) continue;

FrameData clip_frame;
        clip_frame.data = nullptr;
    
   ErrorCode rc = clip->video_engine->getFrame(source_time, &clip_frame);
        if (rc != ErrorCode::SUCCESS) {
            continue;
      }
   
  // SOURCE-AWARE SCALING: Scale relative to original video dimensions, not target canvas
        // This ensures 9:16 videos stay 9:16, 1:1 stays 1:1, etc.
   int scaled_width = static_cast<int>(clip_frame.width * clip->info.scale_x);
 int scaled_height = static_cast<int>(clip_frame.height * clip->info.scale_y);
    
     // Clamp to reasonable bounds
      scaled_width = std::max(1, std::min(scaled_width, target_width * 5));
      scaled_height = std::max(1, std::min(scaled_height, target_height * 5));
    
    FrameData scaled_frame;
        scaled_frame.data = nullptr;
        
        ErrorCode scale_res = Renderer::scaleFrame(&clip_frame, &scaled_frame, scaled_width, scaled_height);
 clip->video_engine->releaseFrame(&clip_frame);
      
if (scale_res != ErrorCode::SUCCESS) {
      continue;
        }
      
        if (first_clip) {
          // First clip: create result canvas and composite centered
          int canvas_size = target_width * target_height * 4;
     if (!result->data) {
  result->data = new uint8_t[canvas_size];
 }
   // Fill with black
          std::memset(result->data, 0, canvas_size);
            result->width = target_width;
    result->height = target_height;
result->format = 0;
            result->timestamp_ms = timestamp_ms;
   
            // Center the scaled frame
            int offset_x = (target_width - scaled_width) / 2;
    int offset_y = (target_height - scaled_height) / 2;
            
            Renderer::blendFramesWithOffset(result, &scaled_frame, result, 1.0f, offset_x, offset_y);
            delete[] scaled_frame.data;
   first_clip = false;
  } else {
            // Subsequent clips: blend centered
 int offset_x = (target_width - scaled_width) / 2;
            int offset_y = (target_height - scaled_height) / 2;
            
      Renderer::blendFramesWithOffset(result, &scaled_frame, result, 1.0f, offset_x, offset_y);
            delete[] scaled_frame.data;
        }
    }
    
    if (first_clip) {
        return ErrorCode::ERROR_DECODE_FAILED;
    }
    
  return ErrorCode::SUCCESS;
}

int64_t Timeline::getTotalDuration() {
    int64_t max_end = 0;
    for (const auto& pair : clips_) {
        max_end = std::max(max_end, pair.second.info.end_time_ms);
    }
    return max_end;
}

// NEW: Capture complete timeline state
TimelineState Timeline::captureState() const {
    TimelineState state;
    state.clips = clips_;
    state.text_layers = text_layers_;
    state.tracks = tracks_;
  state.next_clip_id = next_clip_id_;
    state.next_text_layer_id = next_text_layer_id_;
    state.next_track_id = next_track_id_;
    return state;
}

// NEW: Restore complete timeline state
void Timeline::restoreState(const TimelineState& state) {
    clips_ = state.clips;
  text_layers_ = state.text_layers;
    tracks_ = state.tracks;
    next_clip_id_ = state.next_clip_id;
    next_text_layer_id_ = state.next_text_layer_id;
    next_track_id_ = state.next_track_id;
}

void Timeline::pushState() {
    // Capture complete state (clips + text + tracks + IDs)
    undo_stack_.push_back(captureState());
    
    if (undo_stack_.size() > max_history_) {
  undo_stack_.erase(undo_stack_.begin());
    }
    
    // Clear redo stack when new action is performed
    redo_stack_.clear();
}

bool Timeline::canUndo() {
    return !undo_stack_.empty();
}

bool Timeline::canRedo() {
    return !redo_stack_.empty();
}

ErrorCode Timeline::undo() {
    if (!canUndo()) {
      return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    // Save current state to redo stack
    redo_stack_.push_back(captureState());
    
    // Restore previous state
    restoreState(undo_stack_.back());
    undo_stack_.pop_back();
    
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::redo() {
 if (!canRedo()) {
  return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    // Save current state to undo stack
    undo_stack_.push_back(captureState());
    
    // Restore next state
 restoreState(redo_stack_.back());
    redo_stack_.pop_back();
    
    return ErrorCode::SUCCESS;
}

void Timeline::clearHistory() {
    undo_stack_.clear();
    redo_stack_.clear();
}

int Timeline::addTextLayer(const TextLayer* layer) {
    if (!layer) return -1;
    
    // Validate track type
    auto track_it = tracks_.find(layer->track_index);
    if (track_it != tracks_.end()) {
  TrackType track_type = track_it->second.track_type;
        
        // Only TEXT and OVERLAY tracks can contain text layers
        if (track_type != TrackType::TEXT && track_type != TrackType::OVERLAY) {
    return -1;
        }
    }
    
    TextLayer new_layer = *layer;
 new_layer.layer_id = next_text_layer_id_++;
    text_layers_[new_layer.layer_id] = new_layer;
    
  pushState(); // NEW: Add pushState for undo/redo
    return new_layer.layer_id;
}

ErrorCode Timeline::removeTextLayer(int layer_id) {
    auto it = text_layers_.find(layer_id);
    if (it == text_layers_.end()) {
   return ErrorCode::ERROR_INVALID_PARAMETER;
    }
  
    text_layers_.erase(it);
    pushState(); // NEW: Add pushState for undo/redo
    return ErrorCode::SUCCESS;
}

ErrorCode Timeline::updateTextLayer(int layer_id, const TextLayer* layer) {
    auto it = text_layers_.find(layer_id);
    if (it == text_layers_.end()) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }
    
    it->second = *layer;
    pushState(); // NEW: Add pushState for undo/redo
 return ErrorCode::SUCCESS;
}

int Timeline::getTextLayerCount() {
    return text_layers_.size();
}

ErrorCode Timeline::getAllTextLayers(TextLayer* layers, int max_count) {
    int i = 0;
    for (const auto& pair : text_layers_) {
        if (i >= max_count) break;
        layers[i++] = pair.second;
    }
    return ErrorCode::SUCCESS;
}

} // namespace videocut

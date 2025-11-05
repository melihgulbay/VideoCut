#ifndef VIDEOCUT_TYPES_H
#define VIDEOCUT_TYPES_H

#include <cstdint>
#include <cstring>

namespace videocut {

// Error codes
enum class ErrorCode {
    SUCCESS = 0,
    ERROR_INVALID_PARAMETER = -1,
    ERROR_NOT_INITIALIZED = -2,
    ERROR_INVALID_FILE = -3,
    ERROR_DECODE_FAILED = -4,
    ERROR_ENCODE_FAILED = -5,
    ERROR_OUT_OF_MEMORY = -6,
    ERROR_EXPORT_FAILED = -7,
    ERROR_UNKNOWN = -99
};

// Clip type enumeration
enum class ClipType {
    VIDEO = 0,      // Video with optional audio
    AUDIO_ONLY = 1  // Audio-only clip (MP3, WAV, etc.)
};

// NEW: Track type enumeration
enum class TrackType {
 VIDEO = 0,      // Can contain video clips (renders video)
    AUDIO = 1,      // Can contain audio clips only (audio mixing)
    TEXT = 2,  // Can contain text layers only
    OVERLAY = 3     // Video with alpha channel support
};

// NEW: Text layer type
enum class TextAlignment {
    LEFT = 0,
    CENTER = 1,
    RIGHT = 2
};

// Frame data for rendering
struct FrameData {
    uint8_t* data;
    int width;
    int height;
    int format; // 0 = RGBA
    int64_t timestamp_ms;
    
    FrameData() : data(nullptr), width(0), height(0), format(0), timestamp_ms(0) {}
};

// Video metadata
struct VideoMetadata {
    int64_t duration_ms;
    int width;
    int height;
    double frame_rate;
    int64_t bitrate;
    char codec[32];
    int audio_channels;
    int audio_sample_rate;
};

// Audio waveform data
struct AudioWaveform {
    float* samples;
    int sample_count;
    int channels;
    
    AudioWaveform() : samples(nullptr), sample_count(0), channels(0) {}
};

// Clip information (updated to support audio clips)
struct ClipInfo {
    int clip_id;
    ClipType clip_type;        // NEW: Video or audio-only
    char filepath[512];
    int track_index;
    int64_t start_time_ms;
    int64_t end_time_ms;
    int64_t duration_ms;
    int64_t trim_start_ms;
    int64_t trim_end_ms;
    double speed;
    float volume;
    bool is_muted;
    float scale_x;             // NEW: Horizontal scale (1.0 = 100%)
    float scale_y;             // NEW: Vertical scale (1.0 = 100%)
    bool lock_aspect_ratio;    // NEW: Lock aspect ratio when scaling
    
    ClipInfo() : clip_id(-1), clip_type(ClipType::VIDEO), filepath{0}, 
     track_index(0), start_time_ms(0), end_time_ms(0), 
       duration_ms(0), trim_start_ms(0), trim_end_ms(0),
      speed(1.0), volume(1.0), is_muted(false),
      scale_x(1.0f), scale_y(1.0f), lock_aspect_ratio(true) {}
};

// Export settings
struct ExportSettings {
    char output_path[512];
    int width;
    int height;
    int bitrate;
    int fps;
    char format[16]; // "mp4", "mov", etc.
  char codec[16];  // "h264", "h265", etc.
    int frame_rate;  // FPS (same as fps for compatibility)
    
    ExportSettings() : output_path{0}, width(1920), height(1080),
    bitrate(5000000), fps(30), format{0}, codec{0}, frame_rate(30) {}
};

// NEW: Render settings shared between preview and exporter
struct RenderSettings {
    int width; // target render width
    int height; // target render height
    int supersample; // supersample factor for higher-quality rasterization
    float dpi_scale; // scale factor for DPI awareness (1.0 = default)
    bool use_gpu; // if true and GPU path available, prefer GPU

    RenderSettings() : width(1920), height(1080), supersample(1), dpi_scale(1.0f), use_gpu(false) {}
};

// NEW: Text layer information
struct TextLayer {
    int layer_id;
    char text[512];
    int track_index;
    int64_t start_time_ms;
    int64_t end_time_ms;
    
    // Position (0-1 normalized coordinates)
    float x;  // 0.0 = left, 1.0 = right
    float y;  // 0.0 = top, 1.0 = bottom
    
    // Size and style
    int font_size;
    char font_family[64];
    
    // Color (RGBA 0-255)
    int color_r;
    int color_g;
    int color_b;
    int color_a;
    
// Background color (RGBA 0-255)
    int bg_color_r;
    int bg_color_g;
    int bg_color_b;
    int bg_color_a;
    
    // Transform
    float rotation;  // degrees
    float scale;
    TextAlignment alignment;
    
    // Style flags
    bool bold;
    bool italic;
    bool underline;
    bool has_background;
    
    TextLayer() : layer_id(-1), text{0}, track_index(0),
    start_time_ms(0), end_time_ms(0),
        x(0.5f), y(0.5f),
    font_size(48), font_family{0},
        color_r(255), color_g(255), color_b(255), color_a(255),
        bg_color_r(0), bg_color_g(0), bg_color_b(0), bg_color_a(0),
        rotation(0.0f), scale(1.0f), alignment(TextAlignment::CENTER),
      bold(false), italic(false), underline(false), has_background(false) {
        strcpy(font_family, "Arial");
    }
};

// NEW: Track metadata
struct TrackInfo {
    int track_id;
    TrackType track_type;
    char track_name[64];
    int display_order;
    bool is_locked;
    bool is_visible;
    float opacity;
    
    TrackInfo() : track_id(-1), track_type(TrackType::VIDEO), track_name{0},
         display_order(0), is_locked(false), is_visible(true), opacity(1.0f) {}
};

} // namespace videocut

#endif // VIDEOCUT_TYPES_H

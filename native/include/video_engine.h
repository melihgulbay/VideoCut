#ifndef VIDEOCUT_VIDEO_ENGINE_H
#define VIDEOCUT_VIDEO_ENGINE_H

#include "types.h"
#include <string>
#include <memory>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libswscale/swscale.h>
}

namespace videocut {

class VideoEngine {
public:
    VideoEngine();
    ~VideoEngine();

 // Import and metadata
    ErrorCode loadVideo(const char* filepath);
    ErrorCode getMetadata(VideoMetadata* metadata);
    void closeVideo();

    // Playback and seeking
    ErrorCode seekTo(int64_t timestamp_ms);
    ErrorCode getFrame(int64_t timestamp_ms, FrameData* frame);
  ErrorCode getNextFrame(FrameData* frame);

    // Frame manipulation
    void releaseFrame(FrameData* frame);

    // Utility
    bool isLoaded() const { return format_ctx_ != nullptr; }
    int64_t getDuration() const;

    // Extract audio from video to MP3 file
    ErrorCode extractAudioToFile(const char* output_path);

private:
    AVFormatContext* format_ctx_;
    AVCodecContext* video_codec_ctx_;
  AVCodecContext* audio_codec_ctx_;
    SwsContext* sws_ctx_;
    AVFrame* frame_;
    AVPacket* packet_;
    
    int video_stream_idx_;
    int audio_stream_idx_;
    
    int64_t last_timestamp_;

    ErrorCode initializeCodecs();
    ErrorCode decodeFrame(AVFrame* frame, int64_t target_pts);
};

} // namespace videocut

#endif // VIDEOCUT_VIDEO_ENGINE_H

#ifndef VIDEOCUT_AUDIO_ENGINE_H
#define VIDEOCUT_AUDIO_ENGINE_H

#include "types.h"

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>
}

#include <vector>
#include <cstdint>

namespace videocut {

class AudioEngine {
public:
    AudioEngine();
    ~AudioEngine();

    // Load audio from file (video or audio-only)
    ErrorCode loadAudio(const char* filepath);
    
    // Get audio metadata
    ErrorCode getAudioMetadata(int64_t* duration_ms, int* channels, int* sample_rate);
    
    // Generate waveform for visualization
    ErrorCode generateWaveform(AudioWaveform* waveform, int sample_count);
    
    // Extract audio samples at specific time range
    ErrorCode extractAudioSegment(int64_t start_ms, int64_t end_ms, 
       uint8_t** audio_data, int* data_size);
    
    // Check if file is audio-only (no video stream)
    bool isAudioOnly() const;
 
    void closeAudio();

private:
    ErrorCode initializeCodec();
    ErrorCode decodeAudioSegment(int64_t start_pts, int64_t end_pts, 
        std::vector<uint8_t>& buffer);

    AVFormatContext* format_ctx_;
    AVCodecContext* codec_ctx_;
    SwrContext* swr_ctx_;
    AVFrame* frame_;
    AVPacket* packet_;
    int audio_stream_idx_;
    bool is_audio_only_;  // Track if this is an audio-only file
};

} // namespace videocut

#endif // VIDEOCUT_AUDIO_ENGINE_H

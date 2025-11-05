#include "audio_engine.h"
#include <algorithm>
#include <cmath>
#include <iostream>

extern "C" {
#include <libavutil/opt.h>
#include <libavutil/channel_layout.h>
#include <libswresample/swresample.h>
}

namespace videocut {

AudioEngine::AudioEngine() 
 : format_ctx_(nullptr), codec_ctx_(nullptr), 
 swr_ctx_(nullptr), audio_stream_idx_(-1), is_audio_only_(false) {
}

AudioEngine::~AudioEngine() {
    closeAudio();
}

ErrorCode AudioEngine::loadAudio(const char* filepath) {
    std::cout << "[C++] AudioEngine::loadAudio: Opening file: " << filepath << std::endl;
    
    if (avformat_open_input(&format_ctx_, filepath, nullptr, nullptr) < 0) {
      std::cerr << "[C++] AudioEngine::loadAudio: Failed to open file" << std::endl;
        return ErrorCode::ERROR_INVALID_FILE;
    }

    std::cout << "[C++] AudioEngine::loadAudio: Finding stream info..." << std::endl;
  if (avformat_find_stream_info(format_ctx_, nullptr) < 0) {
        std::cerr << "[C++] AudioEngine::loadAudio: Failed to find stream info" << std::endl;
        avformat_close_input(&format_ctx_);
 return ErrorCode::ERROR_DECODE_FAILED;
    }

    // Find audio and video streams
    std::cout << "[C++] AudioEngine::loadAudio: Looking for audio stream in " 
     << format_ctx_->nb_streams << " streams" << std::endl;
    
    audio_stream_idx_ = -1;
    int video_stream_idx = -1;
    
    for (unsigned i = 0; i < format_ctx_->nb_streams; i++) {
   AVMediaType codec_type = format_ctx_->streams[i]->codecpar->codec_type;
        if (codec_type == AVMEDIA_TYPE_AUDIO && audio_stream_idx_ == -1) {
         audio_stream_idx_ = i;
        } else if (codec_type == AVMEDIA_TYPE_VIDEO && video_stream_idx == -1) {
            video_stream_idx = i;
        }
  }

    if (audio_stream_idx_ == -1) {
        std::cerr << "[C++] AudioEngine::loadAudio: No audio stream found" << std::endl;
        avformat_close_input(&format_ctx_);
        return ErrorCode::ERROR_INVALID_FILE;
    }

    // Determine if this is an audio-only file
    is_audio_only_ = (video_stream_idx == -1);
    std::cout << "[C++] AudioEngine::loadAudio: File type: " 
              << (is_audio_only_ ? "AUDIO-ONLY" : "VIDEO+AUDIO") << std::endl;
    
    std::cout << "[C++] AudioEngine::loadAudio: Found audio stream at index " 
              << audio_stream_idx_ << std::endl;

    std::cout << "[C++] AudioEngine::loadAudio: Initializing codec..." << std::endl;
    ErrorCode result = initializeCodec();
    if (result != ErrorCode::SUCCESS) {
        closeAudio();
        return result;
    }

  frame_ = av_frame_alloc();
    packet_ = av_packet_alloc();

    if (!frame_ || !packet_) {
        closeAudio();
    return ErrorCode::ERROR_OUT_OF_MEMORY;
    }

    return ErrorCode::SUCCESS;
}

ErrorCode AudioEngine::initializeCodec() {
    AVCodecParameters* codecpar = format_ctx_->streams[audio_stream_idx_]->codecpar;
    const AVCodec* codec = avcodec_find_decoder(codecpar->codec_id);
    
    if (!codec) {
        std::cerr << "[C++] AudioEngine: Failed to find codec" << std::endl;
        return ErrorCode::ERROR_DECODE_FAILED;
    }

    codec_ctx_ = avcodec_alloc_context3(codec);
    if (!codec_ctx_) {
   return ErrorCode::ERROR_OUT_OF_MEMORY;
    }

if (avcodec_parameters_to_context(codec_ctx_, codecpar) < 0) {
    return ErrorCode::ERROR_DECODE_FAILED;
}

// Ensure channel layout is set properly
if (codec_ctx_->ch_layout.nb_channels == 0) {
    // Set default channel layout based on channel count
    if (codecpar->ch_layout.nb_channels > 0) {
        codec_ctx_->ch_layout.nb_channels = codecpar->ch_layout.nb_channels;
        // Copy the channel layout if available
        if (codecpar->ch_layout.order != AV_CHANNEL_ORDER_UNSPEC) {
            codec_ctx_->ch_layout = codecpar->ch_layout;
        } else {
            // Set default layout based on channel count
            if (codecpar->ch_layout.nb_channels == 1) {
                av_channel_layout_default(&codec_ctx_->ch_layout, 1);
            } else if (codecpar->ch_layout.nb_channels == 2) {
                av_channel_layout_default(&codec_ctx_->ch_layout, 2);
            } else {
                av_channel_layout_default(&codec_ctx_->ch_layout, codecpar->ch_layout.nb_channels);
            }
        }
    } else {
        // Default to stereo if no channel info
        codec_ctx_->ch_layout.nb_channels = 2;
        av_channel_layout_default(&codec_ctx_->ch_layout, 2);
    }
}

    // Enable multi-threading
    codec_ctx_->thread_count = 0;

    if (avcodec_open2(codec_ctx_, codec, nullptr) < 0) {
        return ErrorCode::ERROR_DECODE_FAILED;
  }

 return ErrorCode::SUCCESS;
}

ErrorCode AudioEngine::getAudioMetadata(int64_t* duration_ms, int* channels, int* sample_rate) {
    if (!format_ctx_ || !codec_ctx_) {
   return ErrorCode::ERROR_NOT_INITIALIZED;
    }

    if (duration_ms) {
      *duration_ms = (format_ctx_->duration * 1000) / AV_TIME_BASE;
    }
 
    if (channels) {
        *channels = codec_ctx_->ch_layout.nb_channels;
    }
    
    if (sample_rate) {
        *sample_rate = codec_ctx_->sample_rate;
  }

    return ErrorCode::SUCCESS;
}

bool AudioEngine::isAudioOnly() const {
    return is_audio_only_;
}

ErrorCode AudioEngine::generateWaveform(AudioWaveform* waveform, int sample_count) {
    std::cout << "[C++] AudioEngine::generateWaveform: Starting waveform generation" << std::endl;
    
    if (!format_ctx_ || !codec_ctx_) {
        std::cerr << "[C++] AudioEngine::generateWaveform: Not initialized" << std::endl;
        return ErrorCode::ERROR_NOT_INITIALIZED;
    }

    AVStream* audio_stream = format_ctx_->streams[audio_stream_idx_];
    int64_t duration_pts = audio_stream->duration;
 
    if (duration_pts <= 0) {
        duration_pts = (format_ctx_->duration * audio_stream->time_base.den) / 
           (AV_TIME_BASE * audio_stream->time_base.num);
 }

    std::cout << "[C++] AudioEngine::generateWaveform: Decoding audio segment..." << std::endl;
    std::cout << "[C++] AudioEngine::generateWaveform: Duration: " << duration_pts << " samples" << std::endl;
    
    std::vector<uint8_t> audio_buffer;
    ErrorCode result = decodeAudioSegment(0, duration_pts, audio_buffer);
    
    if (result != ErrorCode::SUCCESS) {
std::cerr << "[C++] AudioEngine::generateWaveform: Decode failed" << std::endl;
        return result;
    }

    std::cout << "[C++] AudioEngine::generateWaveform: Decoded " << audio_buffer.size() << " bytes of audio" << std::endl;

    if (audio_buffer.empty()) {
        waveform->samples = nullptr;
        waveform->sample_count = 0;
        waveform->channels = 0;
  return ErrorCode::SUCCESS;
    }

    int channels = codec_ctx_->ch_layout.nb_channels;
    int total_samples = audio_buffer.size() / (sizeof(float) * channels);
    
    std::cout << "[C++] AudioEngine::generateWaveform: Total samples: " << total_samples 
 << ", downsampling to " << sample_count << std::endl;

    waveform->samples = new float[sample_count];
    waveform->sample_count = sample_count;
    waveform->channels = channels;

    float* audio_data = reinterpret_cast<float*>(audio_buffer.data());
    int samples_per_bin = std::max(1, total_samples / sample_count);

    for (int i = 0; i < sample_count; i++) {
        float max_amplitude = 0.0f;
        int start_idx = i * samples_per_bin;
        int end_idx = std::min(start_idx + samples_per_bin, total_samples);

        for (int j = start_idx; j < end_idx; j++) {
        float sample = 0.0f;
    for (int ch = 0; ch < channels; ch++) {
       sample += std::abs(audio_data[j * channels + ch]);
    }
       sample /= channels;
   max_amplitude = std::max(max_amplitude, sample);
        }

        waveform->samples[i] = std::min(1.0f, max_amplitude);
    }

    std::cout << "[C++] AudioEngine::generateWaveform: Waveform generation complete" << std::endl;
    return ErrorCode::SUCCESS;
}

ErrorCode AudioEngine::extractAudioSegment(int64_t start_ms, int64_t end_ms,
              uint8_t** audio_data, int* data_size) {
    if (!format_ctx_ || !codec_ctx_) {
        return ErrorCode::ERROR_NOT_INITIALIZED;
    }

    AVStream* audio_stream = format_ctx_->streams[audio_stream_idx_];
    
    // Convert milliseconds to PTS
    int64_t start_pts = (start_ms * audio_stream->time_base.den) / 
              (audio_stream->time_base.num * 1000);
    int64_t end_pts = (end_ms * audio_stream->time_base.den) / 
     (audio_stream->time_base.num * 1000);

    std::vector<uint8_t> buffer;
    ErrorCode result = decodeAudioSegment(start_pts, end_pts, buffer);
    
    if (result != ErrorCode::SUCCESS || buffer.empty()) {
        return result;
    }

    // The decodeAudioSegment returns interleaved float samples at codec sample rate
    *data_size = static_cast<int>(buffer.size());
    *audio_data = new uint8_t[*data_size];
    std::copy(buffer.begin(), buffer.end(), *audio_data);
 
 return ErrorCode::SUCCESS;
 }

ErrorCode AudioEngine::decodeAudioSegment(int64_t start_pts, int64_t end_pts,
     std::vector<uint8_t>& buffer) {
    std::cout << "[C++] AudioEngine::decodeAudioSegment: start_pts=" << start_pts 
       << ", end_pts=" << end_pts << std::endl;

    AVStream* audio_stream = format_ctx_->streams[audio_stream_idx_];

    std::cout << "[C++] AudioEngine::decodeAudioSegment: Seeking to start..." << std::endl;
    if (av_seek_frame(format_ctx_, audio_stream_idx_, start_pts, AVSEEK_FLAG_BACKWARD) < 0) {
        std::cerr << "[C++] AudioEngine::decodeAudioSegment: Seek failed" << std::endl;
 return ErrorCode::ERROR_DECODE_FAILED;
    }

    avcodec_flush_buffers(codec_ctx_);

    std::cout << "[C++] AudioEngine::decodeAudioSegment: Reading frames..." << std::endl;
    
    int frame_count = 0;
    while (av_read_frame(format_ctx_, packet_) >= 0) {
     if (packet_->stream_index == audio_stream_idx_) {
 if (packet_->pts > end_pts) {
         av_packet_unref(packet_);
 break;
        }

    if (avcodec_send_packet(codec_ctx_, packet_) == 0) {
      while (avcodec_receive_frame(codec_ctx_, frame_) == 0) {
      frame_count++;

   // Only process frames within time range
    if (frame_->pts < start_pts) {
               continue;
          }

   int data_size = av_samples_get_buffer_size(nullptr, 
     codec_ctx_->ch_layout.nb_channels,
      frame_->nb_samples,
               AV_SAMPLE_FMT_FLT, 1);

 if (data_size > 0) {
      size_t old_size = buffer.size();
       buffer.resize(old_size + data_size);

    // Reuse existing swr_ctx_ if it matches desired output (float interleaved at codec sample rate)
    if (!swr_ctx_) {
        // Create swr context for converting to float interleaved
        swr_ctx_ = swr_alloc();
        if (!swr_ctx_) {
            return ErrorCode::ERROR_DECODE_FAILED;
        }
        
        // Use the codec context's channel layout for both input and output
        av_opt_set_chlayout(swr_ctx_, "in_chlayout", &codec_ctx_->ch_layout, 0);
        av_opt_set_int(swr_ctx_, "in_sample_rate", codec_ctx_->sample_rate, 0);
        av_opt_set_sample_fmt(swr_ctx_, "in_sample_fmt", codec_ctx_->sample_fmt, 0);
        
        av_opt_set_chlayout(swr_ctx_, "out_chlayout", &codec_ctx_->ch_layout, 0);
        av_opt_set_int(swr_ctx_, "out_sample_rate", codec_ctx_->sample_rate, 0);
        av_opt_set_sample_fmt(swr_ctx_, "out_sample_fmt", AV_SAMPLE_FMT_FLT, 0);
        
        if (swr_init(swr_ctx_) < 0) {
            swr_free(&swr_ctx_);
            swr_ctx_ = nullptr;
            return ErrorCode::ERROR_DECODE_FAILED;
        }
    }
    
     uint8_t* out[] = { buffer.data() + old_size };
     swr_convert(swr_ctx_, out, frame_->nb_samples, (const uint8_t**)frame_->data, frame_->nb_samples);
  }
}
  }
    }
     av_packet_unref(packet_);
    }

  std::cout << "[C++] AudioEngine::decodeAudioSegment: Decoded " << frame_count 
 << " frames, buffer size: " << buffer.size() << " bytes" << std::endl;

  return ErrorCode::SUCCESS;
}

void AudioEngine::closeAudio() {
    if (frame_) {
   av_frame_free(&frame_);
    }
    if (packet_) {
        av_packet_free(&packet_);
    }
    if (swr_ctx_) {
swr_free(&swr_ctx_);
    }
    if (codec_ctx_) {
   avcodec_free_context(&codec_ctx_);
    }
    if (format_ctx_) {
        avformat_close_input(&format_ctx_);
    }
    
    audio_stream_idx_ = -1;
    is_audio_only_ = false;
}

} // namespace videocut

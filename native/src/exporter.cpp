#include "exporter.h"
#include "renderer.h"
#include "simple_text_renderer.h"
#include "audio_engine.h"
#include <iostream>
#include <cmath>
#include <algorithm>
#include <map>
#include <memory>
#include <vector>

extern "C" {
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>
}

namespace videocut {

Exporter::Exporter() 
    : output_ctx_(nullptr), video_encoder_ctx_(nullptr), 
      audio_encoder_ctx_(nullptr), video_stream_(nullptr), 
      audio_stream_(nullptr), is_exporting_(false), 
      export_progress_(0.0f), cancel_requested_(false) {
}

Exporter::~Exporter() {
    cleanup();
}

ErrorCode Exporter::startExport(Timeline* timeline, const ExportSettings* settings) {
    if (is_exporting_) {
        std::cerr << "[C++] Exporter: Already exporting, rejecting new export" << std::endl;
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }
    
    if (output_ctx_ != nullptr || video_encoder_ctx_ != nullptr || audio_encoder_ctx_ != nullptr) {
   std::cerr << "[C++] Exporter: WARNING: Previous export not cleaned up, forcing cleanup" << std::endl;
  cleanup();
    }

    is_exporting_ = true;
    cancel_requested_ = false;
 export_progress_ = 0.0f;

    ErrorCode result = initializeEncoder(settings);
 if (result != ErrorCode::SUCCESS) {
        cleanup();
   is_exporting_ = false;
        return result;
    }

    int64_t duration = timeline->getTotalDuration();
    
    result = encodeVideo(timeline, duration);
  if (result != ErrorCode::SUCCESS) {
        cleanup();
        is_exporting_ = false;
        return result;
    }

    result = encodeAudioFromClips(timeline, duration);
  if (result != ErrorCode::SUCCESS) {
        cleanup();
        is_exporting_ = false;
        return result;
 }

    if (output_ctx_) {
  av_write_trailer(output_ctx_);
        std::cout << "[C++] Export: Trailer written, file finalized" << std::endl;
    }

    cleanup();
    is_exporting_ = false;
    export_progress_ = 1.0f;
    
    std::cout << "[C++] Export: Complete!" << std::endl;
    return ErrorCode::SUCCESS;
}

ErrorCode Exporter::initializeEncoder(const ExportSettings* settings) {
    if (output_ctx_ != nullptr) {
        std::cerr << "[C++] Exporter: ERROR: output_ctx already exists, cleanup not called!" << std::endl;
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }

  std::cout << "[C++] Exporter::initializeEncoder: output_path = '" << settings->output_path << "'" << std::endl;
    std::cout << "[C++] Exporter::initializeEncoder: format = '" << settings->format << "'" << std::endl;
    std::cout << "[C++] Exporter::initializeEncoder: codec = '" << settings->codec << "'" << std::endl;
 std::cout << "[C++] Exporter::initializeEncoder: resolution = " << settings->width << "x" << settings->height << std::endl;
    
    // Allocate output format context
    avformat_alloc_output_context2(&output_ctx_, nullptr, nullptr, settings->output_path);
    if (!output_ctx_) {
        std::cerr << "[C++] Exporter::initializeEncoder: Failed to allocate output context" << std::endl;
        return ErrorCode::ERROR_ENCODE_FAILED;
    }

    // Find video codec
    const AVCodec* video_codec = avcodec_find_encoder_by_name(settings->codec);
    if (!video_codec) {
        video_codec = avcodec_find_encoder(AV_CODEC_ID_H264);
    }
    if (!video_codec) {
        return ErrorCode::ERROR_ENCODE_FAILED;
    }

    // Create video stream
    video_stream_ = avformat_new_stream(output_ctx_, nullptr);
    if (!video_stream_) {
        return ErrorCode::ERROR_ENCODE_FAILED;
    }

    // Initialize video encoder context
    video_encoder_ctx_ = avcodec_alloc_context3(video_codec);
    if (!video_encoder_ctx_) {
        return ErrorCode::ERROR_OUT_OF_MEMORY;
    }

    video_encoder_ctx_->width = settings->width;
    video_encoder_ctx_->height = settings->height;
    video_encoder_ctx_->time_base = AVRational{1, static_cast<int>(settings->frame_rate)};
    video_encoder_ctx_->framerate = AVRational{static_cast<int>(settings->frame_rate), 1};
    video_encoder_ctx_->bit_rate = settings->bitrate;
    video_encoder_ctx_->gop_size = 12;
    video_encoder_ctx_->max_b_frames = 2;
    video_encoder_ctx_->pix_fmt = AV_PIX_FMT_YUV420P;

    if (output_ctx_->oformat->flags & AVFMT_GLOBALHEADER) {
        video_encoder_ctx_->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
    }

    if (avcodec_open2(video_encoder_ctx_, video_codec, nullptr) < 0) {
        return ErrorCode::ERROR_ENCODE_FAILED;
    }

    avcodec_parameters_from_context(video_stream_->codecpar, video_encoder_ctx_);
    video_stream_->time_base = video_encoder_ctx_->time_base;

    // Initialize audio encoder for mixing audio from clips
    const AVCodec* audio_codec = avcodec_find_encoder(AV_CODEC_ID_AAC);
    if (audio_codec) {
        audio_stream_ = avformat_new_stream(output_ctx_, nullptr);
        if (audio_stream_) {
            audio_encoder_ctx_ = avcodec_alloc_context3(audio_codec);
            if (audio_encoder_ctx_) {
                audio_encoder_ctx_->sample_rate = 48000;
                audio_encoder_ctx_->ch_layout = AV_CHANNEL_LAYOUT_STEREO;
                audio_encoder_ctx_->sample_fmt = AV_SAMPLE_FMT_FLTP;
                audio_encoder_ctx_->bit_rate = 256000;  // Increased from 192k to 256k for better quality
                audio_encoder_ctx_->time_base = AVRational{1, 48000};

                if (output_ctx_->oformat->flags & AVFMT_GLOBALHEADER) {
                    audio_encoder_ctx_->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
                }

                if (avcodec_open2(audio_encoder_ctx_, audio_codec, nullptr) == 0) {
                    avcodec_parameters_from_context(audio_stream_->codecpar, audio_encoder_ctx_);
                    audio_stream_->time_base = audio_encoder_ctx_->time_base;
                    std::cout << "[C++] Audio encoder initialized: 48kHz stereo AAC @ 256kbps" << std::endl;
                } else {
                    avcodec_free_context(&audio_encoder_ctx_);
                    audio_encoder_ctx_ = nullptr;
                    audio_stream_ = nullptr;
                }
            }
        }
    }

    // Open output file
    if (!(output_ctx_->oformat->flags & AVFMT_NOFILE)) {
        if (avio_open(&output_ctx_->pb, settings->output_path, AVIO_FLAG_WRITE) < 0) {
            return ErrorCode::ERROR_ENCODE_FAILED;
        }
    }

    // Write header
    if (avformat_write_header(output_ctx_, nullptr) < 0) {
        return ErrorCode::ERROR_ENCODE_FAILED;
    }

    return ErrorCode::SUCCESS;
}

ErrorCode Exporter::encodeVideo(Timeline* timeline, int64_t duration_ms) {
    AVFrame* frame = av_frame_alloc();
    AVPacket* packet = av_packet_alloc();
    SwsContext* sws_ctx = nullptr;

    if (!frame || !packet) {
        av_frame_free(&frame);
        av_packet_free(&packet);
        return ErrorCode::ERROR_OUT_OF_MEMORY;
    }

    frame->format = video_encoder_ctx_->pix_fmt;
    frame->width = video_encoder_ctx_->width;
    frame->height = video_encoder_ctx_->height;
    av_frame_get_buffer(frame, 0);

    int64_t frame_duration_ms = 1000 / video_encoder_ctx_->framerate.num;
    int64_t pts = 0;

    std::cout << "[C++] Export: Text layers will be rendered by timeline" << std::endl;

    // Track last source dimensions for sws_ctx recreation
    int last_src_width = 0;
    int last_src_height = 0;

    // Calculate output canvas dimensions
    const int output_width = video_encoder_ctx_->width;
const int output_height = video_encoder_ctx_->height;

    // Prepare RenderSettings - render at EXPORT dimensions (same as preview)
    // This ensures preview and export match exactly
 RenderSettings rs;
    rs.width = output_width;   // Use export dimensions
 rs.height = output_height; // Use export dimensions
    rs.supersample = 2;
    rs.dpi_scale = 1.0f;
    rs.use_gpu = false;

    std::cout << "[C++] Export: Output canvas: " << output_width << "x" << output_height << std::endl;
    std::cout << "[C++] Export: Render size: " << rs.width << "x" << rs.height << std::endl;

    for (int64_t timestamp_ms = 0; timestamp_ms < duration_ms; timestamp_ms += frame_duration_ms) {
        if (cancel_requested_) {
            av_frame_free(&frame);
            av_packet_free(&packet);
      if (sws_ctx) sws_freeContext(sws_ctx);
         return ErrorCode::ERROR_INVALID_PARAMETER;
        }

 // Render frame from timeline at preview size
   FrameData rendered_frame;
        rendered_frame.data = nullptr;
        ErrorCode result = timeline->renderFrameAt(timestamp_ms, &rendered_frame, &rs);
   
      if (result == ErrorCode::SUCCESS && rendered_frame.data != nullptr) {
      // Frame rendered successfully - just convert RGBA to YUV and encode
     // No letterboxing needed since render size = output size
       
       // Recreate sws_ctx if needed
       if (!sws_ctx || last_src_width != rendered_frame.width || last_src_height != rendered_frame.height) {
  if (sws_ctx) sws_freeContext(sws_ctx);
        
      sws_ctx = sws_getContext(
 rendered_frame.width, rendered_frame.height, AV_PIX_FMT_RGBA,
     output_width, output_height, 
     AV_PIX_FMT_YUV420P, SWS_BICUBIC, nullptr, nullptr, nullptr
             );
         
    last_src_width = rendered_frame.width;
            last_src_height = rendered_frame.height;
   }

      const uint8_t* src_data[1] = { rendered_frame.data };
 int src_linesize[1] = { rendered_frame.width * 4 };
   
        sws_scale(sws_ctx, src_data, src_linesize, 0, rendered_frame.height,
frame->data, frame->linesize);

timeline->renderFrameAt(0, &rendered_frame);
     } else {
        // No clips - fill with black
   int y_size = frame->width * frame->height;
            int uv_size = (frame->width / 2) * (frame->height / 2);
       memset(frame->data[0], 16, y_size);
            memset(frame->data[1], 128, uv_size);
            memset(frame->data[2], 128, uv_size);
      }

     frame->pts = pts++;

      if (avcodec_send_frame(video_encoder_ctx_, frame) == 0) {
            while (avcodec_receive_packet(video_encoder_ctx_, packet) == 0) {
                av_packet_rescale_ts(packet, video_encoder_ctx_->time_base, video_stream_->time_base);
          packet->stream_index = video_stream_->index;
       av_interleaved_write_frame(output_ctx_, packet);
    av_packet_unref(packet);
            }
 }

        export_progress_ = static_cast<float>(timestamp_ms) / duration_ms;
    }

    avcodec_send_frame(video_encoder_ctx_, nullptr);
    while (avcodec_receive_packet(video_encoder_ctx_, packet) == 0) {
      av_packet_rescale_ts(packet, video_encoder_ctx_->time_base, video_stream_->time_base);
   packet->stream_index = video_stream_->index;
        av_interleaved_write_frame(output_ctx_, packet);
        av_packet_unref(packet);
    }

    av_frame_free(&frame);
    av_packet_free(&packet);
    if (sws_ctx) sws_freeContext(sws_ctx);

    export_progress_ = 0.8f;
    std::cout << "[C++] Export: Video encoding complete" << std::endl;
    return ErrorCode::SUCCESS;
}

ErrorCode Exporter::encodeAudioFromClips(Timeline* timeline, int64_t duration_ms) {
    if (!audio_encoder_ctx_ || !audio_stream_) {
        std::cout << "[C++] Export: No audio encoder, skipping audio" << std::endl;
        return ErrorCode::SUCCESS;
    }

    std::cout << "[C++] Export: Starting audio encoding from audio-only clips" << std::endl;

    // Get all clips to find audio-only ones
    int clip_count = timeline->getClipCount();
    ClipInfo* clips = new ClipInfo[clip_count];
    timeline->getAllClips(clips, clip_count);

    // Filter audio-only clips
    std::vector<ClipInfo> audio_clips;
    for (int i = 0; i < clip_count; i++) {
        if (clips[i].clip_type == ClipType::AUDIO_ONLY) {
            audio_clips.push_back(clips[i]);
            std::cout << "[C++] Export: Found audio clip " << clips[i].clip_id 
                << " at track " << clips[i].track_index 
                << " from " << clips[i].start_time_ms << "ms to " << clips[i].end_time_ms << "ms" << std::endl;
        }
    }
    delete[] clips;

    if (audio_clips.empty()) {
        std::cout << "[C++] Export: No audio clips found, encoding silence" << std::endl;
    } else {
        std::cout << "[C++] Export: Processing " << audio_clips.size() << " audio clips" << std::endl;
    }

    AVFrame* frame = av_frame_alloc();
    AVPacket* packet = av_packet_alloc();
    
    if (!frame || !packet) {
        av_frame_free(&frame);
        av_packet_free(&packet);
        return ErrorCode::ERROR_OUT_OF_MEMORY;
    }

    frame->format = audio_encoder_ctx_->sample_fmt;
    frame->ch_layout = audio_encoder_ctx_->ch_layout;
    frame->sample_rate = audio_encoder_ctx_->sample_rate;
    frame->nb_samples = audio_encoder_ctx_->frame_size > 0 ? audio_encoder_ctx_->frame_size : 1024;
    av_frame_get_buffer(frame, 0);

    int64_t sample_duration_ms = (frame->nb_samples * 1000) / frame->sample_rate;
    int64_t pts = 0;

    // Open audio engines for each unique audio file
    std::map<std::string, std::shared_ptr<AudioEngine>> audio_engines;

    for (int64_t timestamp_ms = 0; timestamp_ms < duration_ms; timestamp_ms += sample_duration_ms) {
        if (cancel_requested_) {
            av_frame_free(&frame);
            av_packet_free(&packet);
            // Close all audio engines
            audio_engines.clear();
            return ErrorCode::ERROR_INVALID_PARAMETER;
        }

        // Initialize frame with silence
        av_samples_set_silence(frame->data, 0, frame->nb_samples,
            frame->ch_layout.nb_channels,
            (AVSampleFormat)frame->format);

        // Mix audio from active audio-only clips
        for (const auto& clip : audio_clips) {
            // Check if clip is active at this timestamp
            if (timestamp_ms >= clip.start_time_ms && timestamp_ms < clip.end_time_ms) {
                // Calculate source position accounting for trim and speed
                int64_t clip_offset_ms = timestamp_ms - clip.start_time_ms;
                int64_t source_time_ms = clip.trim_start_ms + static_cast<int64_t>(clip_offset_ms * clip.speed);
       
                // Clamp to trim boundaries
                if (source_time_ms >= clip.trim_start_ms && source_time_ms < clip.trim_end_ms) {
                    // Prefer existing audio engine attached to clip in Timeline
                    std::shared_ptr<AudioEngine> engine = timeline->getAudioEngineForClip(clip.clip_id);
                    if (!engine) {
                        // Fallback to local cache
                        std::string filepath(clip.filepath);
                        if (audio_engines.find(filepath) == audio_engines.end()) {
                            auto e = std::make_shared<AudioEngine>();
                            if (e->loadAudio(filepath.c_str()) == ErrorCode::SUCCESS) {
                                audio_engines[filepath] = e;
                                std::cout << "[C++] Export: Loaded audio from " << filepath << std::endl;
                            } else {
                                std::cout << "[C++] Export: Failed to load audio from " << filepath << std::endl;
                                continue;
                            }
                        }
                        engine = audio_engines[filepath];
                    }

                    // Decode audio samples from the engine
                    uint8_t* audio_data = nullptr;
                    int data_size = 0;
    
                    // Calculate end time for this buffer
                    int64_t end_time_ms = source_time_ms + sample_duration_ms;
                    if (end_time_ms > clip.trim_end_ms) {
                        end_time_ms = clip.trim_end_ms;
                    }
          
                    // Extract audio segment
                    if (engine->extractAudioSegment(source_time_ms, end_time_ms, &audio_data, &data_size) == ErrorCode::SUCCESS && audio_data && data_size > 0) {
                        // Mix decoded samples into frame
                        // extractAudioSegment returns interleaved stereo float samples
                        int sample_count = data_size / (sizeof(float) * 2); // 2 channels
                        float* src_samples = reinterpret_cast<float*>(audio_data);
   
                        // Get destination buffer (FLTP format = planar float)
                        float* dst_left = reinterpret_cast<float*>(frame->data[0]);
                        float* dst_right = reinterpret_cast<float*>(frame->data[1]);

                        // Mix samples with volume normalization to prevent clipping
                        // Use a slight attenuation to prevent clipping when mixing multiple clips
                        int samples_to_mix = std::min(sample_count, frame->nb_samples);
                        for (int s = 0; s < samples_to_mix; s++) {
                            // Apply slight attenuation (0.9) to prevent clipping while preserving quality
                            float left_sample = src_samples[s * 2] * 0.9f;
                            float right_sample = src_samples[s * 2 + 1] * 0.9f;
        
                            dst_left[s] += left_sample;
                            dst_right[s] += right_sample;
                        }
 
                        delete[] audio_data;
                    }
                }
            }
        }

        // Clamp mixed samples to prevent distortion
        float* left = reinterpret_cast<float*>(frame->data[0]);
        float* right = reinterpret_cast<float*>(frame->data[1]);
        for (int s = 0; s < frame->nb_samples; s++) {
            left[s] = std::clamp(left[s], -1.0f, 1.0f);
            right[s] = std::clamp(right[s], -1.0f, 1.0f);
        }

        frame->pts = pts;
        pts += frame->nb_samples;

        // Encode frame
        if (avcodec_send_frame(audio_encoder_ctx_, frame) == 0) {
            while (avcodec_receive_packet(audio_encoder_ctx_, packet) == 0) {
                av_packet_rescale_ts(packet, audio_encoder_ctx_->time_base, audio_stream_->time_base);
                packet->stream_index = audio_stream_->index;
                av_interleaved_write_frame(output_ctx_, packet);
                av_packet_unref(packet);
            }
        }
    }

    // Flush encoder
    avcodec_send_frame(audio_encoder_ctx_, nullptr);
    while (avcodec_receive_packet(audio_encoder_ctx_, packet) == 0) {
        av_packet_rescale_ts(packet, audio_encoder_ctx_->time_base, audio_stream_->time_base);
        packet->stream_index = audio_stream_->index;
        av_interleaved_write_frame(output_ctx_, packet);
        av_packet_unref(packet);
    }

    av_frame_free(&frame);
    av_packet_free(&packet);
    
    // Close all audio engines
    for (auto& pair : audio_engines) {
        pair.second->closeAudio();
    }
    audio_engines.clear();

    export_progress_ = 1.0f;
    std::cout << "[C++] Export: Audio encoding complete" << std::endl;
    return ErrorCode::SUCCESS;
}

ErrorCode Exporter::getProgress(float* progress) {
    *progress = export_progress_;
    return ErrorCode::SUCCESS;
}

ErrorCode Exporter::cancelExport() {
    cancel_requested_ = true;
    return ErrorCode::SUCCESS;
}

void Exporter::cleanup() {
    if (video_encoder_ctx_) {
        avcodec_free_context(&video_encoder_ctx_);
        video_encoder_ctx_ = nullptr;
    }
    if (audio_encoder_ctx_) {
        avcodec_free_context(&audio_encoder_ctx_);
        audio_encoder_ctx_ = nullptr;
    }
    if (output_ctx_) {
        if (!(output_ctx_->oformat->flags & AVFMT_NOFILE)) {
            avio_closep(&output_ctx_->pb);
        }
        avformat_free_context(output_ctx_);
        output_ctx_ = nullptr;
    }
    video_stream_ = nullptr;
    audio_stream_ = nullptr;
}

} // namespace videocut

#include "video_engine.h"
#include <iostream>

namespace videocut {

VideoEngine::VideoEngine() 
    : format_ctx_(nullptr), video_codec_ctx_(nullptr), 
      audio_codec_ctx_(nullptr), sws_ctx_(nullptr),
      frame_(nullptr), packet_(nullptr),
      video_stream_idx_(-1), audio_stream_idx_(-1),
      last_timestamp_(0) {
}

VideoEngine::~VideoEngine() {
    closeVideo();
}

ErrorCode VideoEngine::loadVideo(const char* filepath) {
    // Open video file
    if (avformat_open_input(&format_ctx_, filepath, nullptr, nullptr) < 0) {
      return ErrorCode::ERROR_INVALID_FILE;
    }

 // Retrieve stream information
    if (avformat_find_stream_info(format_ctx_, nullptr) < 0) {
    avformat_close_input(&format_ctx_);
        return ErrorCode::ERROR_DECODE_FAILED;
    }

    // Find video and audio streams - optimized single loop
    video_stream_idx_ = -1;
    audio_stream_idx_ = -1;
    
    for (unsigned i = 0; i < format_ctx_->nb_streams; i++) {
        AVMediaType codec_type = format_ctx_->streams[i]->codecpar->codec_type;
        if (codec_type == AVMEDIA_TYPE_VIDEO && video_stream_idx_ == -1) {
 video_stream_idx_ = i;
          if (audio_stream_idx_ != -1) break; // Found both
        } else if (codec_type == AVMEDIA_TYPE_AUDIO && audio_stream_idx_ == -1) {
            audio_stream_idx_ = i;
 if (video_stream_idx_ != -1) break; // Found both
 }
    }

    if (video_stream_idx_ == -1) {
        avformat_close_input(&format_ctx_);
        return ErrorCode::ERROR_INVALID_FILE;
    }

    ErrorCode result = initializeCodecs();
    if (result != ErrorCode::SUCCESS) {
  closeVideo();
        return result;
    }

    // Allocate frame and packet
    frame_ = av_frame_alloc();
    packet_ = av_packet_alloc();
    
 if (!frame_ || !packet_) {
  closeVideo();
     return ErrorCode::ERROR_OUT_OF_MEMORY;
    }

    return ErrorCode::SUCCESS;
}

ErrorCode VideoEngine::initializeCodecs() {
    // Initialize video codec
    AVCodecParameters* codecpar = format_ctx_->streams[video_stream_idx_]->codecpar;
    const AVCodec* codec = avcodec_find_decoder(codecpar->codec_id);
    
    if (!codec) {
   return ErrorCode::ERROR_DECODE_FAILED;
 }

    video_codec_ctx_ = avcodec_alloc_context3(codec);
    if (!video_codec_ctx_) {
        return ErrorCode::ERROR_OUT_OF_MEMORY;
    }

    if (avcodec_parameters_to_context(video_codec_ctx_, codecpar) < 0) {
        return ErrorCode::ERROR_DECODE_FAILED;
    }

    // Enable multi-threading for decoding
 video_codec_ctx_->thread_count = 0; // Auto-detect CPU cores

  if (avcodec_open2(video_codec_ctx_, codec, nullptr) < 0) {
   return ErrorCode::ERROR_DECODE_FAILED;
    }

    // Initialize audio codec if available
    if (audio_stream_idx_ >= 0) {
        codecpar = format_ctx_->streams[audio_stream_idx_]->codecpar;
        codec = avcodec_find_decoder(codecpar->codec_id);

        if (codec) {
            audio_codec_ctx_ = avcodec_alloc_context3(codec);
         if (audio_codec_ctx_) {
              avcodec_parameters_to_context(audio_codec_ctx_, codecpar);
     audio_codec_ctx_->thread_count = 0;
   avcodec_open2(audio_codec_ctx_, codec, nullptr);
      }
      }
    }

    return ErrorCode::SUCCESS;
}

ErrorCode VideoEngine::getMetadata(VideoMetadata* metadata) {
    if (!format_ctx_) {
        return ErrorCode::ERROR_NOT_INITIALIZED;
    }

    AVStream* video_stream = format_ctx_->streams[video_stream_idx_];
    
    metadata->duration_ms = (format_ctx_->duration * 1000) / AV_TIME_BASE;
    metadata->width = video_codec_ctx_->width;
metadata->height = video_codec_ctx_->height;
    metadata->frame_rate = av_q2d(video_stream->r_frame_rate);
    metadata->bitrate = format_ctx_->bit_rate;
    
    const AVCodec* codec = avcodec_find_decoder(video_codec_ctx_->codec_id);
    snprintf(metadata->codec, sizeof(metadata->codec), "%s", codec ? codec->name : "unknown");

    if (audio_codec_ctx_) {
      metadata->audio_channels = audio_codec_ctx_->ch_layout.nb_channels;
 metadata->audio_sample_rate = audio_codec_ctx_->sample_rate;
    } else {
        metadata->audio_channels = 0;
        metadata->audio_sample_rate = 0;
    }

    return ErrorCode::SUCCESS;
}

ErrorCode VideoEngine::seekTo(int64_t timestamp_ms) {
    if (!format_ctx_) {
        return ErrorCode::ERROR_NOT_INITIALIZED;
    }

    AVStream* stream = format_ctx_->streams[video_stream_idx_];
    int64_t pts = (timestamp_ms * stream->time_base.den) / (stream->time_base.num * 1000);
    
    if (av_seek_frame(format_ctx_, video_stream_idx_, pts, AVSEEK_FLAG_BACKWARD) < 0) {
      return ErrorCode::ERROR_DECODE_FAILED;
    }

    avcodec_flush_buffers(video_codec_ctx_);
    last_timestamp_ = timestamp_ms;
    
    return ErrorCode::SUCCESS;
}

ErrorCode VideoEngine::getFrame(int64_t timestamp_ms, FrameData* frame_data) {
 if (!format_ctx_) {
        return ErrorCode::ERROR_NOT_INITIALIZED;
    }

    // Optimized seek decision: only seek if necessary
    const int64_t seek_threshold = 10000; // 10 seconds
    if (timestamp_ms < last_timestamp_ || (timestamp_ms - last_timestamp_) > seek_threshold) {
        seekTo(timestamp_ms);
    }

    AVStream* stream = format_ctx_->streams[video_stream_idx_];
    int64_t target_pts = (timestamp_ms * stream->time_base.den) / (stream->time_base.num * 1000);

while (av_read_frame(format_ctx_, packet_) >= 0) {
        if (packet_->stream_index == video_stream_idx_) {
            if (avcodec_send_packet(video_codec_ctx_, packet_) == 0) {
                if (avcodec_receive_frame(video_codec_ctx_, frame_) == 0) {
          if (frame_->pts >= target_pts) {
             // Initialize SWS context only once and reuse
     if (!sws_ctx_) {
           sws_ctx_ = sws_getContext(
   video_codec_ctx_->width, video_codec_ctx_->height, 
          video_codec_ctx_->pix_fmt,
     video_codec_ctx_->width, video_codec_ctx_->height, 
           AV_PIX_FMT_RGBA, SWS_FAST_BILINEAR, nullptr, nullptr, nullptr
        );
             }

    int rgba_size = video_codec_ctx_->width * video_codec_ctx_->height * 4;
          frame_data->data = new uint8_t[rgba_size];
              frame_data->width = video_codec_ctx_->width;
frame_data->height = video_codec_ctx_->height;
         frame_data->format = 0; // RGBA
  frame_data->timestamp_ms = (frame_->pts * stream->time_base.num * 1000) / 
               stream->time_base.den;

       uint8_t* dest[1] = { frame_data->data };
    int dest_linesize[1] = { video_codec_ctx_->width * 4 };
            
  sws_scale(sws_ctx_, frame_->data, frame_->linesize, 0, 
    video_codec_ctx_->height, dest, dest_linesize);

 av_packet_unref(packet_);
       last_timestamp_ = timestamp_ms;
          return ErrorCode::SUCCESS;
     }
          }
     }
        }
        av_packet_unref(packet_);
    }

    return ErrorCode::ERROR_DECODE_FAILED;
}

ErrorCode VideoEngine::getNextFrame(FrameData* frame_data) {
    return getFrame(last_timestamp_ + 33, frame_data); // ~30fps
}

void VideoEngine::releaseFrame(FrameData* frame_data) {
    if (frame_data && frame_data->data) {
      delete[] frame_data->data;
        frame_data->data = nullptr;
    }
}

int64_t VideoEngine::getDuration() const {
    if (!format_ctx_) {
   return 0;
    }
    return (format_ctx_->duration * 1000) / AV_TIME_BASE;
}

ErrorCode VideoEngine::extractAudioToFile(const char* output_path) {
    if (!format_ctx_ || !output_path) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    std::cout << "[C++] VideoEngine::extractAudioToFile: Extracting audio to " << output_path << std::endl;

    // Find audio stream
    int audio_stream_idx = -1;
    for (unsigned i = 0; i < format_ctx_->nb_streams; i++) {
  if (format_ctx_->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
     audio_stream_idx = i;
    break;
    }
    }

  if (audio_stream_idx == -1) {
        std::cout << "[C++] VideoEngine::extractAudioToFile: No audio stream found" << std::endl;
     return ErrorCode::ERROR_INVALID_FILE;
    }

    AVStream* in_stream = format_ctx_->streams[audio_stream_idx];
    AVCodecID codec_id = in_stream->codecpar->codec_id;
    
    // Determine output format based on input codec
    const char* format_name = nullptr;
    const char* file_ext = nullptr;
    
    // Use the native codec format to avoid re-encoding
 if (codec_id == AV_CODEC_ID_MP3) {
        format_name = "mp3";
      file_ext = ".mp3";
    } else if (codec_id == AV_CODEC_ID_AAC) {
        format_name = "adts"; // AAC in ADTS container
        file_ext = ".aac";
    } else {
    // Default to MP3 for other formats
    format_name = "mp3";
        file_ext = ".mp3";
    }
    
    // Modify output path if needed to match format
    std::string output_path_str(output_path);
    if (output_path_str.find(file_ext) == std::string::npos) {
    // Replace extension
        size_t last_dot = output_path_str.find_last_of('.');
        if (last_dot != std::string::npos) {
        output_path_str = output_path_str.substr(0, last_dot) + file_ext;
        } else {
   output_path_str += file_ext;
        }
    }
    const char* final_output_path = output_path_str.c_str();

    std::cout << "[C++] VideoEngine::extractAudioToFile: Using format '" << format_name 
       << "' for output: " << final_output_path << std::endl;

    // Create output format context
    AVFormatContext* out_fmt_ctx = nullptr;
    avformat_alloc_output_context2(&out_fmt_ctx, nullptr, format_name, final_output_path);
    if (!out_fmt_ctx) {
      std::cerr << "[C++] VideoEngine::extractAudioToFile: Failed to create output context" << std::endl;
  return ErrorCode::ERROR_ENCODE_FAILED;
    }

    // Add audio stream to output
    AVStream* out_stream = avformat_new_stream(out_fmt_ctx, nullptr);
    if (!out_stream) {
        avformat_free_context(out_fmt_ctx);
        return ErrorCode::ERROR_OUT_OF_MEMORY;
    }

    // Copy codec parameters
    avcodec_parameters_copy(out_stream->codecpar, in_stream->codecpar);
    out_stream->codecpar->codec_tag = 0;

    // Open output file
    if (!(out_fmt_ctx->oformat->flags & AVFMT_NOFILE)) {
        if (avio_open(&out_fmt_ctx->pb, final_output_path, AVIO_FLAG_WRITE) < 0) {
            std::cerr << "[C++] VideoEngine::extractAudioToFile: Failed to open output file" << std::endl;
        avformat_free_context(out_fmt_ctx);
            return ErrorCode::ERROR_INVALID_FILE;
        }
    }

    // Write header
    if (avformat_write_header(out_fmt_ctx, nullptr) < 0) {
        std::cerr << "[C++] VideoEngine::extractAudioToFile: Failed to write header" << std::endl;
        avio_closep(&out_fmt_ctx->pb);
        avformat_free_context(out_fmt_ctx);
        return ErrorCode::ERROR_ENCODE_FAILED;
    }

    // Copy audio packets
    AVPacket* pkt = av_packet_alloc();
    av_seek_frame(format_ctx_, audio_stream_idx, 0, AVSEEK_FLAG_BACKWARD);

    int packet_count = 0;
    while (av_read_frame(format_ctx_, pkt) >= 0) {
        if (pkt->stream_index == audio_stream_idx) {
            // Rescale timestamps
   av_packet_rescale_ts(pkt, in_stream->time_base, out_stream->time_base);
 pkt->stream_index = 0;

            // Write packet
 if (av_interleaved_write_frame(out_fmt_ctx, pkt) < 0) {
      std::cerr << "[C++] VideoEngine::extractAudioToFile: Error writing packet" << std::endl;
 break;
  }
            packet_count++;
        }
  av_packet_unref(pkt);
    }

    // Write trailer
    av_write_trailer(out_fmt_ctx);

    // Cleanup
    av_packet_free(&pkt);
  avio_closep(&out_fmt_ctx->pb);
    avformat_free_context(out_fmt_ctx);

    std::cout << "[C++] VideoEngine::extractAudioToFile: Extracted " << packet_count 
     << " audio packets to " << final_output_path << std::endl;

    return ErrorCode::SUCCESS;
}

void VideoEngine::closeVideo() {
    if (frame_) {
  av_frame_free(&frame_);
}
    if (packet_) {
        av_packet_free(&packet_);
    }
    if (sws_ctx_) {
      sws_freeContext(sws_ctx_);
     sws_ctx_ = nullptr;
    }
    if (video_codec_ctx_) {
        avcodec_free_context(&video_codec_ctx_);
    }
    if (audio_codec_ctx_) {
        avcodec_free_context(&audio_codec_ctx_);
    }
    if (format_ctx_) {
        avformat_close_input(&format_ctx_);
    }
}

} // namespace videocut

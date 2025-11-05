#include "renderer.h"
#include <cstring>
#include <algorithm>
#include <memory>

extern "C" {
#include <libswscale/swscale.h>
}

namespace videocut {

Renderer::Renderer() {
}

Renderer::~Renderer() {
}

ErrorCode Renderer::convertFrameToRGBA(AVFrame* src, FrameData* dst) {
    if (!src || !dst) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    SwsContext* sws_ctx = sws_getContext(
        src->width, src->height, static_cast<AVPixelFormat>(src->format),
        src->width, src->height, AV_PIX_FMT_RGBA,
        SWS_FAST_BILINEAR, nullptr, nullptr, nullptr
    );

 if (!sws_ctx) {
        return ErrorCode::ERROR_OUT_OF_MEMORY;
    }

    int rgba_size = src->width * src->height * 4;
    dst->data = new uint8_t[rgba_size];
    dst->width = src->width;
    dst->height = src->height;
    dst->format = 0; // RGBA

    uint8_t* dest[1] = { dst->data };
    int dest_linesize[1] = { src->width * 4 };

    sws_scale(sws_ctx, src->data, src->linesize, 0, src->height, dest, dest_linesize);
    sws_freeContext(sws_ctx);

    return ErrorCode::SUCCESS;
}

ErrorCode Renderer::scaleFrame(const FrameData* src, FrameData* dst, 
         int target_width, int target_height) {
    if (!src || !dst || !src->data) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    SwsContext* sws_ctx = sws_getContext(
        src->width, src->height, AV_PIX_FMT_RGBA,
        target_width, target_height, AV_PIX_FMT_RGBA,
        SWS_FAST_BILINEAR, nullptr, nullptr, nullptr
 );

    if (!sws_ctx) {
        return ErrorCode::ERROR_OUT_OF_MEMORY;
    }

    int rgba_size = target_width * target_height * 4;
    dst->data = new uint8_t[rgba_size];
    dst->width = target_width;
    dst->height = target_height;
    dst->format = 0; // RGBA
    dst->timestamp_ms = src->timestamp_ms;

    const uint8_t* src_data[1] = { src->data };
    int src_linesize[1] = { src->width * 4 };
    uint8_t* dest[1] = { dst->data };
    int dest_linesize[1] = { target_width * 4 };

    sws_scale(sws_ctx, src_data, src_linesize, 0, src->height, dest, dest_linesize);
    sws_freeContext(sws_ctx);

    return ErrorCode::SUCCESS;
}

ErrorCode Renderer::blendFrames(const FrameData* bottom, const FrameData* top, 
    FrameData* result, float opacity) {
    if (!bottom || !top || !result) {
        return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    if (bottom->width != top->width || bottom->height != top->height) {
     return ErrorCode::ERROR_INVALID_PARAMETER;
    }

    int pixel_count = bottom->width * bottom->height;
    
  // If result doesn't have a buffer yet, allocate it
    if (!result->data) {
        result->data = new uint8_t[pixel_count * 4];
result->width = bottom->width;
  result->height = bottom->height;
  result->format = 0;
  result->timestamp_ms = bottom->timestamp_ms;
    }

    const uint8_t* b_data = bottom->data;
    const uint8_t* t_data = top->data;
    uint8_t* r_data = result->data;
    
 for (int i = 0; i < pixel_count * 4; i += 4) {
      float alpha = (t_data[i + 3] / 255.0f) * opacity;
  float inv_alpha = 1.0f - alpha;
     
  r_data[i + 0] = static_cast<uint8_t>(b_data[i + 0] * inv_alpha + t_data[i + 0] * alpha);
        r_data[i + 1] = static_cast<uint8_t>(b_data[i + 1] * inv_alpha + t_data[i + 1] * alpha);
     r_data[i + 2] = static_cast<uint8_t>(b_data[i + 2] * inv_alpha + t_data[i + 2] * alpha);
        r_data[i + 3] = std::max(b_data[i + 3], static_cast<uint8_t>(t_data[i + 3] * opacity));
    }

    return ErrorCode::SUCCESS;
}

ErrorCode Renderer::blendFramesWithOffset(const FrameData* bottom, const FrameData* top,
     FrameData* result, float opacity,
     int offset_x, int offset_y) {
    if (!bottom || !top || !result) {
return ErrorCode::ERROR_INVALID_PARAMETER;
 }
    
    // If result doesn't have a buffer yet, allocate it and copy bottom
    if (!result->data) {
        int size = bottom->width * bottom->height * 4;
        result->data = new uint8_t[size];
        result->width = bottom->width;
        result->height = bottom->height;
  result->format = 0;
        result->timestamp_ms = bottom->timestamp_ms;
        std::memcpy(result->data, bottom->data, size);
    }
    
    // Blend top frame onto result at offset
    for (int y = 0; y < top->height; y++) {
        int dest_y = y + offset_y;
        if (dest_y < 0 || dest_y >= result->height) continue;
        
     for (int x = 0; x < top->width; x++) {
        int dest_x = x + offset_x;
            if (dest_x < 0 || dest_x >= result->width) continue;
    
      int top_idx = (y * top->width + x) * 4;
       int dest_idx = (dest_y * result->width + dest_x) * 4;
    
            float alpha = (top->data[top_idx + 3] / 255.0f) * opacity;
        float inv_alpha = 1.0f - alpha;
            
   result->data[dest_idx + 0] = static_cast<uint8_t>(
       result->data[dest_idx + 0] * inv_alpha + top->data[top_idx + 0] * alpha
    );
            result->data[dest_idx + 1] = static_cast<uint8_t>(
        result->data[dest_idx + 1] * inv_alpha + top->data[top_idx + 1] * alpha
 );
            result->data[dest_idx + 2] = static_cast<uint8_t>(
 result->data[dest_idx + 2] * inv_alpha + top->data[top_idx + 2] * alpha
      );
 result->data[dest_idx + 3] = std::max(
         result->data[dest_idx + 3],
           static_cast<uint8_t>(top->data[top_idx + 3] * opacity)
            );
        }
 }
    
    return ErrorCode::SUCCESS;
}

bool Renderer::isGPUAvailable() {
    // TODO: Implement GPU detection
    return false;
}

ErrorCode Renderer::initializeGPU() {
    // TODO: Implement GPU initialization (CUDA/OpenCL/Metal)
    return ErrorCode::ERROR_NOT_INITIALIZED;
}

} // namespace videocut

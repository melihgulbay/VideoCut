#ifndef VIDEOCUT_RENDERER_H
#define VIDEOCUT_RENDERER_H

#include "types.h"

extern "C" {
#include <libavutil/frame.h>
}

namespace videocut {

class Renderer {
public:
    Renderer();
    ~Renderer();

    // Frame rendering utilities
    static ErrorCode convertFrameToRGBA(AVFrame* src, FrameData* dst);
    static ErrorCode scaleFrame(const FrameData* src, FrameData* dst, 
int target_width, int target_height);
static ErrorCode blendFrames(const FrameData* bottom, const FrameData* top, 
     FrameData* result, float opacity = 1.0f);
    
 // NEW: Blend frames with offset (for scaled clips)
    static ErrorCode blendFramesWithOffset(const FrameData* bottom, const FrameData* top,
           FrameData* result, float opacity,
           int offset_x, int offset_y);
    
    static bool isGPUAvailable();
    static ErrorCode initializeGPU();
};

} // namespace videocut

#endif // VIDEOCUT_RENDERER_H

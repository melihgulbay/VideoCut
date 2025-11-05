#ifndef VIDEOCUT_TEXT_RENDERER_H
#define VIDEOCUT_TEXT_RENDERER_H

#include "types.h"
#include <string>
#include <cmath>

namespace videocut {

class SimpleTextRenderer {
public:
    // Initialize renderer (allocates caches). Call once on startup.
    static void initialize();
    static void shutdown();

    // Render text layer into an RGBA buffer using explicit render settings
    static void renderText(const TextLayer& layer, uint8_t* frame_data,
        int frame_width, int frame_height, const RenderSettings& settings);

    // Backwards-compatible overload (uses default render settings)
    static void renderText(const TextLayer& layer, uint8_t* frame_data,
        int frame_width, int frame_height);

private:
    static void drawChar(char c, int x, int y, uint8_t* frame_data,
          int frame_width, int frame_height,
        int r, int g, int b, int a, int fontSize);
    
    static void drawRect(int x, int y, int width, int height,
            uint8_t* frame_data, int frame_width, int frame_height,
            int r, int g, int b, int a);
    
    static void setPixel(int x, int y, uint8_t* frame_data,
 int frame_width, int frame_height,
          int r, int g, int b, int a);
    
    static int measureText(const char* text, int fontSize);

    // Glyph cache related (private helpers)
    static void clearGlyphCache();
};

} // namespace videocut

#endif // VIDEOCUT_TEXT_RENDERER_H

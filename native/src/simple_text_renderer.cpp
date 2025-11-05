#include "simple_text_renderer.h"
#include <algorithm>
#include <cstring>
#include <vector>
#include <unordered_map>

// Fix M_PI macro definition
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace videocut {

// Simple5x7 bitmap font for basic ASCII characters (32..126)
static const uint8_t font5x7[][7] = {
 {0x00,0x00,0x00,0x00,0x00,0x00,0x00}, //32 ' '
 {0x04,0x04,0x04,0x04,0x00,0x04,0x00}, //33 '!'
 {0x0A,0x0A,0x0A,0x00,0x00,0x00,0x00}, //34 '"'
 {0x0A,0x1F,0x0A,0x0A,0x1F,0x0A,0x00}, //35 '#'
 {0x04,0x0F,0x14,0x0E,0x05,0x1E,0x04}, //36 '$'
 {0x18,0x19,0x02,0x04,0x08,0x13,0x03}, //37 '%'
 {0x0C,0x12,0x14,0x08,0x15,0x12,0x0D}, //38 '&'
 {0x04,0x04,0x04,0x00,0x00,0x00,0x00}, //39 '\''
 {0x02,0x04,0x08,0x08,0x08,0x04,0x02}, //40 '('
 {0x08,0x04,0x02,0x02,0x02,0x04,0x08}, //41 ')'
 {0x00,0x04,0x15,0x0E,0x15,0x04,0x00}, //42 '*'
 {0x00,0x04,0x04,0x1F,0x04,0x04,0x00}, //43 '+'
 {0x00,0x00,0x00,0x00,0x04,0x04,0x08}, //44 ','
 {0x00,0x00,0x00,0x1F,0x00,0x00,0x00}, //45 '-'
 {0x00,0x00,0x00,0x00,0x00,0x04,0x00}, //46 '.'
 {0x00,0x01,0x02,0x04,0x08,0x10,0x00}, //47 '/'
 {0x0E,0x11,0x13,0x15,0x19,0x11,0x0E}, //48 '0'
 {0x04,0x0C,0x04,0x04,0x04,0x04,0x0E}, //49 '1'
 {0x0E,0x11,0x01,0x02,0x04,0x08,0x1F}, //50 '2'
 {0x1F,0x02,0x04,0x02,0x01,0x11,0x0E}, //51 '3'
 {0x02,0x06,0x0A,0x12,0x1F,0x02,0x02}, //52 '4'
 {0x1F,0x10,0x1E,0x01,0x01,0x11,0x0E}, //53 '5'
 {0x06,0x08,0x10,0x1E,0x11,0x11,0x0E}, //54 '6'
 {0x1F,0x01,0x02,0x04,0x08,0x08,0x08}, //55 '7'
 {0x0E,0x11,0x11,0x0E,0x11,0x11,0x0E}, //56 '8'
 {0x0E,0x11,0x11,0x0F,0x01,0x02,0x0C}, //57 '9'
 {0x00,0x04,0x00,0x00,0x04,0x00,0x00}, //58 ':'
 {0x00,0x04,0x00,0x00,0x04,0x04,0x08}, //59 ';'
 {0x02,0x04,0x08,0x10,0x08,0x04,0x02}, //60 '<'
 {0x00,0x00,0x1F,0x00,0x1F,0x00,0x00}, //61 '='
 {0x08,0x04,0x02,0x01,0x02,0x04,0x08}, //62 '>'
 {0x0E,0x11,0x01,0x02,0x04,0x00,0x04}, //63 '?'
 {0x0E,0x11,0x01,0x0D,0x15,0x15,0x0E}, //64 '@'
 {0x0E,0x11,0x11,0x11,0x1F,0x11,0x11}, //65 'A'
 {0x1E,0x11,0x11,0x1E,0x11,0x11,0x1E}, //66 'B'
 {0x0E,0x11,0x10,0x10,0x10,0x11,0x0E}, //67 'C'
 {0x1C,0x12,0x11,0x11,0x11,0x12,0x1C}, //68 'D'
 {0x1F,0x10,0x10,0x1E,0x10,0x10,0x1F}, //69 'E'
 {0x1F,0x10,0x10,0x1E,0x10,0x10,0x10}, //70 'F'
 {0x0E,0x11,0x10,0x17,0x11,0x11,0x0F}, //71 'G'
 {0x11,0x11,0x11,0x1F,0x11,0x11,0x11}, //72 'H'
 {0x0E,0x04,0x04,0x04,0x04,0x04,0x0E}, //73 'I'
 {0x07,0x02,0x02,0x02,0x02,0x12,0x0C}, //74 'J'
 {0x11,0x12,0x14,0x18,0x14,0x12,0x11}, //75 'K'
 {0x10,0x10,0x10,0x10,0x10,0x10,0x1F}, //76 'L'
 {0x11,0x1B,0x15,0x15,0x11,0x11,0x11}, //77 'M'
 {0x11,0x11,0x19,0x15,0x13,0x11,0x11}, //78 'N'
 {0x0E,0x11,0x11,0x11,0x11,0x11,0x0E}, //79 'O'
 {0x1E,0x11,0x11,0x1E,0x10,0x10,0x10}, //80 'P'
 {0x0E,0x11,0x11,0x11,0x15,0x12,0x0D}, //81 'Q'
 {0x1E,0x11,0x11,0x1E,0x14,0x12,0x11}, //82 'R'
 {0x0F,0x10,0x10,0x0E,0x01,0x01,0x1E}, //83 'S'
 {0x1F,0x04,0x04,0x04,0x04,0x04,0x04}, //84 'T'
 {0x11,0x11,0x11,0x11,0x11,0x11,0x0E}, //85 'U'
 {0x11,0x11,0x11,0x11,0x11,0x0A,0x04}, //86 'V'
 {0x11,0x11,0x11,0x15,0x15,0x15,0x0A}, //87 'W'
 {0x11,0x11,0x0A,0x04,0x0A,0x11,0x11}, //88 'X'
 {0x11,0x11,0x11,0x0A,0x04,0x04,0x04}, //89 'Y'
 {0x1F,0x01,0x02,0x04,0x08,0x10,0x1F}, //90 'Z'
};

// Simple glyph cache key and cache
struct GlyphBitmap {
 int width;
 int height;
 std::vector<uint8_t> pixels; // RGBA
};

static std::unordered_map<uint64_t, GlyphBitmap> glyph_cache;

static uint64_t make_glyph_key(int ch, int size, int ss) {
 return (static_cast<uint64_t>(ch) &0xFFFF) | ((static_cast<uint64_t>(size) &0xFFFF) <<16) | ((static_cast<uint64_t>(ss) &0xFFFF) <<32);
}

static void setPixelInBuffer(uint8_t* buf, int buf_w, int buf_h, int x, int y,
 int r, int g, int b, int a) {
 if (x <0 || x >= buf_w || y <0 || y >= buf_h) return;
 int idx = (y * buf_w + x) *4;
 float alpha = a /255.0f;
 buf[idx +0] = (uint8_t)(r * alpha + buf[idx +0] * (1 - alpha));
 buf[idx +1] = (uint8_t)(g * alpha + buf[idx +1] * (1 - alpha));
 buf[idx +2] = (uint8_t)(b * alpha + buf[idx +2] * (1 - alpha));
 buf[idx +3] =255;
}

// Draw a character into an arbitrary RGBA buffer using bitmap glyphs and integer scaling
static void drawCharToBuffer(const uint8_t* glyph, int buf_w, int buf_h, int x, int y,
 uint8_t* buf, int r, int g, int b, int a, int scale) {
 for (int row =0; row <7; row++) {
 uint8_t bits = glyph[row];
 for (int col =0; col <5; col++) {
 // Use MSB as leftmost bit in the byte (bit4 down to0)
 if (bits & (1 << (4 - col))) {
 for (int sy =0; sy < scale; sy++) {
 for (int sx =0; sx < scale; sx++) {
 setPixelInBuffer(buf, buf_w, buf_h, x + col * scale + sx, y + row * scale + sy, r, g, b, a);
 }
 }
 }
 }
 }
}

static void rasterize_glyph_cached(int ch, int size, int supersample, GlyphBitmap& out) {
 uint64_t key = make_glyph_key(ch, size, supersample);
 auto it = glyph_cache.find(key);
 if (it != glyph_cache.end()) {
 out = it->second;
 return;
 }

 // Rasterize using existing bitmap font with integer scaling and supersample
 int baseScale = std::max(1, size /7);
 int hiScale = baseScale * supersample;
 int glyph_w =5 * hiScale;
 int glyph_h =7 * hiScale;
 out.width = glyph_w;
 out.height = glyph_h;
 out.pixels.assign(glyph_w * glyph_h *4,0);

 int charIndex = ch -32;
 if (charIndex <0 || charIndex >= static_cast<int>(sizeof(font5x7) / sizeof(font5x7[0]))) {
 // empty glyph
 glyph_cache[key] = out;
 return;
 }
 const uint8_t* glyph = font5x7[charIndex];

 // Draw into out.pixels
 drawCharToBuffer(glyph, glyph_w, glyph_h,0,0, out.pixels.data(),255,255,255,255, hiScale);

 // Store in cache
 glyph_cache[key] = out;
}

static void drawGlyphBitmapToBuffer(const GlyphBitmap& gb, uint8_t* dst, int dst_w, int dst_h, int dst_x, int dst_y, int r, int g, int b, int a) {
 for (int y =0; y < gb.height; y++) {
 for (int x =0; x < gb.width; x++) {
 int sidx = (y * gb.width + x) *4;
 int alpha = gb.pixels[sidx +3];
 if (alpha ==0) continue;
 int dx = dst_x + x;
 int dy = dst_y + y;
 if (dx <0 || dx >= dst_w || dy <0 || dy >= dst_h) continue;
 int idx = (dy * dst_w + dx) *4;
 float af = alpha /255.0f;
 dst[idx +0] = (uint8_t)(r * af + dst[idx +0] * (1 - af));
 dst[idx +1] = (uint8_t)(g * af + dst[idx +1] * (1 - af));
 dst[idx +2] = (uint8_t)(b * af + dst[idx +2] * (1 - af));
 dst[idx +3] =255;
 }
 }
}

void SimpleTextRenderer::initialize() {
 // placeholder for initializing glyph cache, font loading etc.
 glyph_cache.clear();
}

void SimpleTextRenderer::shutdown() {
 glyph_cache.clear();
}

void SimpleTextRenderer::drawChar(char c, int x, int y, uint8_t* frame_data,
 int frame_width, int frame_height,
 int r, int g, int b, int a, int fontSize) {
 // Map lowercase to uppercase if glyphs only defined for uppercase
 if (c >= 'a' && c <= 'z') c = char(c - 'a' + 'A');

 unsigned char uc = static_cast<unsigned char>(c);
 int charIndex = (int)uc -32; // ASCII offset
 const int fontCount = static_cast<int>(sizeof(font5x7) / sizeof(font5x7[0]));
 if (charIndex <0 || charIndex >= fontCount) return; // Out of supported range

 const uint8_t* glyph = font5x7[charIndex];
 int scale = std::max(1, fontSize /7);

 for (int row =0; row <7; row++) {
 uint8_t bits = glyph[row];
 for (int col =0; col <5; col++) {
 if (bits & (1 << (4 - col))) {
 // Draw scaled pixel
 for (int sy =0; sy < scale; sy++) {
 for (int sx =0; sx < scale; sx++) {
 setPixel(x + col * scale + sx, y + row * scale + sy,
 frame_data, frame_width, frame_height, r, g, b, a);
 }
 }
 }
 }
 }
}

int SimpleTextRenderer::measureText(const char* text, int fontSize) {
 int scale = std::max(1, fontSize /7);
 return (int)std::strlen(text) *6 * scale; //5 pixels +1 spacing
}

// Overload for backward compatibility: delegate to new API with default settings
void SimpleTextRenderer::renderText(const TextLayer& layer, uint8_t* frame_data,
 int frame_width, int frame_height) {
 RenderSettings rs;
 rs.width = frame_width;
 rs.height = frame_height;
 rs.supersample =1;
 rs.dpi_scale =1.0f;
 rs.use_gpu = false;
 renderText(layer, frame_data, frame_width, frame_height, rs);
}

void SimpleTextRenderer::renderText(const TextLayer& layer, uint8_t* frame_data,
 int frame_width, int frame_height, const RenderSettings& settings) {
 if (!frame_data || layer.text[0] == '\0') return;

 // Use a reference resolution (1920x1080) for consistent positioning and sizing
 // Text coordinates and font sizes are designed for this resolution
 const int REF_WIDTH = 1920;
 const int REF_HEIGHT = 1080;
 
 // Calculate scale factors relative to reference resolution
 float scaleX = static_cast<float>(frame_width) / REF_WIDTH;
 float scaleY = static_cast<float>(frame_height) / REF_HEIGHT;
 
 // Use the smaller scale to maintain aspect ratio
 float uniformScale = std::min(scaleX, scaleY);

 // Scale font size to current resolution
 int fontSize = std::clamp(static_cast<int>(layer.font_size * uniformScale), 12, 400);
 int baseScale = std::max(1, fontSize /7);
 int textWidth = measureText(layer.text, fontSize);
 int textHeight =7 * baseScale;

 // Draw background first so text is on top
 if (layer.has_background) {
 int bgWidth = (int)(textWidth * layer.scale) +16;
 int bgHeight = (int)(textHeight * layer.scale) +8;
 // Use reference resolution for positioning, then scale
 int startX = (int)((layer.x * REF_WIDTH) * scaleX) - textWidth /2 -8;
 int startY = (int)((layer.y * REF_HEIGHT) * scaleY) - textHeight /2 -4;
 drawRect(startX, startY, bgWidth, bgHeight, frame_data, frame_width, frame_height,
 layer.bg_color_r, layer.bg_color_g, layer.bg_color_b, layer.bg_color_a);
 }

 // Use supersample from settings (if >1) to rasterize glyphs at higher detail and then downsample
 int SS = std::max(1, settings.supersample);
 int hiScale = baseScale * SS;
 int hiTextWidth = textWidth * SS;
 int hiTextHeight = textHeight * SS;

 if (hiTextWidth <=0 || hiTextHeight <=0) return;

 std::vector<uint8_t> hiBuf(hiTextWidth * hiTextHeight *4);
 std::fill(hiBuf.begin(), hiBuf.end(),0);

 // Draw chars into hi-res buffer using glyph cache
 int cursorX =0;
 size_t len = std::strlen(layer.text);
 for (size_t i =0; i < len; i++) {
 char c = layer.text[i];
 if (c == '\n') {
 cursorX =0;
 continue;
 }
 if (c >= 'a' && c <= 'z') c = char(c - 'a' + 'A');
 unsigned char uc = static_cast<unsigned char>(c);
 int ch = (int)uc;
 int glyphSize = fontSize; // glyph size key
 GlyphBitmap gb;
 rasterize_glyph_cached(ch, glyphSize, SS, gb);
 if (gb.pixels.empty()) {
 cursorX +=6 * baseScale * SS;
 continue;
 }
 drawGlyphBitmapToBuffer(gb, hiBuf.data(), hiTextWidth, hiTextHeight, cursorX,0,
 layer.color_r, layer.color_g, layer.color_b, layer.color_a);
 cursorX += gb.width + (1 * SS); // glyph spacing
 }

 // Downsample hiBuf into frame
 // Use reference resolution for positioning, then scale
 int centerX = (int)((layer.x * REF_WIDTH) * scaleX);
 int centerY = (int)((layer.y * REF_HEIGHT) * scaleY);
 int startX = centerX - textWidth /2;
 int startY = centerY - textHeight /2;

 for (int ty =0; ty < textHeight; ty++) {
 for (int tx =0; tx < textWidth; tx++) {
 int accR =0, accG =0, accB =0, accA =0;
 for (int sy =0; sy < SS; sy++) {
 for (int sx =0; sx < SS; sx++) {
 int hx = tx * SS + sx;
 int hy = ty * SS + sy;
 int hidx = (hy * hiTextWidth + hx) *4;
 accR += hiBuf[hidx +0];
 accG += hiBuf[hidx +1];
 accB += hiBuf[hidx +2];
 accA += hiBuf[hidx +3];
 }
 }
 int samples = SS * SS;
 int r = accR / samples;
 int g = accG / samples;
 int b = accB / samples;
 int a = accA / samples;

 int fx = startX + tx;
 int fy = startY + ty;
 if (fx <0 || fx >= frame_width || fy <0 || fy >= frame_height) continue;

 int fidx = (fy * frame_width + fx) *4;
 float alpha = a /255.0f;
 frame_data[fidx +0] = (uint8_t)(r * alpha + frame_data[fidx +0] * (1 - alpha));
 frame_data[fidx +1] = (uint8_t)(g * alpha + frame_data[fidx +1] * (1 - alpha));
 frame_data[fidx +2] = (uint8_t)(b * alpha + frame_data[fidx +2] * (1 - alpha));
 frame_data[fidx +3] =255;
 }
 }

 // Underline if enabled
 if (layer.underline) {
 int lineY = startY + (int)(textHeight * layer.scale) +2;
 drawRect(startX, lineY, (int)(textWidth * layer.scale),2,
 frame_data, frame_width, frame_height,
 layer.color_r, layer.color_g, layer.color_b, layer.color_a);
 }
}

void SimpleTextRenderer::drawRect(int x, int y, int width, int height,
 uint8_t* frame_data, int frame_width, int frame_height,
 int r, int g, int b, int a) {
 for (int yy =0; yy < height; yy++) {
 for (int xx =0; xx < width; xx++) {
 int fx = x + xx;
 int fy = y + yy;
 if (fx <0 || fx >= frame_width || fy <0 || fy >= frame_height) continue;
 int idx = (fy * frame_width + fx) *4;
 float alpha = a /255.0f;
 frame_data[idx +0] = (uint8_t)(r * alpha + frame_data[idx +0] * (1 - alpha));
 frame_data[idx +1] = (uint8_t)(g * alpha + frame_data[idx +1] * (1 - alpha));
 frame_data[idx +2] = (uint8_t)(b * alpha + frame_data[idx +2] * (1 - alpha));
 frame_data[idx +3] =255;
 }
 }
}

void SimpleTextRenderer::setPixel(int x, int y, uint8_t* frame_data,
 int frame_width, int frame_height,
 int r, int g, int b, int a) {
 if (x <0 || x >= frame_width || y <0 || y >= frame_height) return;
 int idx = (y * frame_width + x) *4;
 float alpha = a /255.0f;
 frame_data[idx +0] = (uint8_t)(r * alpha + frame_data[idx +0] * (1 - alpha));
 frame_data[idx +1] = (uint8_t)(g * alpha + frame_data[idx +1] * (1 - alpha));
 frame_data[idx +2] = (uint8_t)(b * alpha + frame_data[idx +2] * (1 - alpha));
 frame_data[idx +3] =255;
}

} // namespace videocut

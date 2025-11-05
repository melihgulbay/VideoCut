#ifndef VIDEOCUT_EXPORTER_H
#define VIDEOCUT_EXPORTER_H

#include "types.h"
#include "timeline.h"
#include <memory>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
}

namespace videocut {

class Exporter {
public:
    Exporter();
    ~Exporter();

    // Export operations
    ErrorCode startExport(Timeline* timeline, const ExportSettings* settings);
    ErrorCode getProgress(float* progress);
    ErrorCode cancelExport();
    bool isExporting() const { return is_exporting_; }

private:
    AVFormatContext* output_ctx_;
    AVCodecContext* video_encoder_ctx_;
    AVCodecContext* audio_encoder_ctx_;
    AVStream* video_stream_;
    AVStream* audio_stream_;
 
    bool is_exporting_;
    float export_progress_;
    bool cancel_requested_;

    ErrorCode initializeEncoder(const ExportSettings* settings);
    ErrorCode encodeVideo(Timeline* timeline, int64_t duration_ms);
    ErrorCode encodeAudioFromClips(Timeline* timeline, int64_t duration_ms);
    void cleanup();
};

} // namespace videocut

#endif // VIDEOCUT_EXPORTER_H

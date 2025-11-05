import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/editor_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/toolbar.dart';
import '../widgets/video_preview.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/properties/properties_panel.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final editorNotifier = ref.read(editorProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Column(
        children: [
          const Toolbar(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    color: AppColors.secondaryBlack,
                    child: const VideoPreview(),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: editorState.selectedTextLayerId != null
                      ? PropertiesPanel(textLayerId: editorState.selectedTextLayerId)
                      : editorState.selectedClipId != null
                          ? PropertiesPanel(clipId: editorState.selectedClipId!)
                          : Container(
                              color: AppColors.tertiaryBlack,
                              child: Center(
                                child: Text(
                                  'No clip selected',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 250,
            child: TimelineWidget(
              clips: editorState.clips,
              currentTimeMs: editorState.currentTimeMs,
              selectedClipId: editorState.selectedClipId,
              zoom: editorState.zoom,
              scrollOffset: editorState.scrollOffset,
              clipWaveforms: editorState.clipWaveforms,
              trackCount: editorState.trackCount,
              tracks: editorState.tracks,
              textLayers: editorState.textLayers,
              selectedTextLayerId: editorState.selectedTextLayerId,
              onSeek: editorNotifier.seekTo,
              onClipSelect: editorNotifier.selectClip,
              onClipMove: editorNotifier.moveClip,
              onClipChangeTrack: editorNotifier.changeClipTrack,
              onZoomChange: editorNotifier.setZoom,
              onScroll: editorNotifier.scroll,
              onTextLayerSelect: editorNotifier.selectTextLayer,
              onTextLayerMove: editorNotifier.moveTextLayer,
            ),
          ),
        ],
      ),
    );
  }
}

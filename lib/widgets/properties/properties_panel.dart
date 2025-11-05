import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/editor_provider.dart';
import '../../native/video_engine_wrapper.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import 'text_properties_panel.dart';
import 'video_properties_panel.dart';
import 'audio_properties_panel.dart';

/// Main properties panel that routes to specialized panels based on selection
class PropertiesPanel extends ConsumerWidget {
  final int? clipId;
  final int? textLayerId;

  const PropertiesPanel({
    super.key,
    this.clipId,
    this.textLayerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show text properties if text layer is selected
    if (textLayerId != null) {
      return TextPropertiesPanel(layerId: textLayerId!);
    }

    // Show clip properties if clip is selected
    if (clipId != null) {
      final editorState = ref.watch(editorProvider);

      final clip = editorState.clips.firstWhere(
        (c) => c.clipId == clipId,
        orElse: () => ClipData(
          clipId: -1,
          startTimeMs: 0,
          endTimeMs: 0,
          trimStartMs: 0,
          trimEndMs: 0,
        ),
      );

      if (clip.clipId == -1) {
        return _buildEmptyState(
          context,
          icon: Icons.error_outline,
          title: 'Clip Not Found',
          message: 'The selected clip no longer exists',
        );
      }

      // Route to appropriate panel based on clip type
      if (clip.isAudioOnly) {
        return AudioPropertiesPanel(clip: clip);
      } else {
        return VideoPropertiesPanel(clip: clip);
      }
    }

    // Show empty state if nothing is selected
    return _buildEmptyState(
      context,
      icon: Icons.info_outline,
      title: 'No Selection',
      message: 'Select a clip or text layer to view properties',
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      color: AppColors.secondaryBlack,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              title,
              style: AppTypography.headingMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/editor_provider.dart';
import '../../native/video_engine_wrapper.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';

class VideoPropertiesPanel extends ConsumerWidget {
  final ClipData clip;

  const VideoPropertiesPanel({
    super.key,
    required this.clip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final editorNotifier = ref.read(editorProvider.notifier);
    final metadata = editorState.clipMetadata[clip.clipId];

    return Container(
      color: AppColors.secondaryBlack,
      padding: const EdgeInsets.all(AppSpacing.m),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.videocam,
                  color: AppColors.trackVideo,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Properties',
                        style: AppTypography.headingMedium,
                      ),
                      Text(
                        'Clip ${clip.clipId}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            const Divider(height: 1, color: AppColors.dividerColor),
            const SizedBox(height: AppSpacing.l),

            // Playback Speed
            _buildSection(
              context,
              'Playback Speed',
              Icons.speed,
              Column(
                children: [
                  Slider(
                    value: clip.speed,
                    min: 0.25,
                    max: 4.0,
                    divisions: 15,
                    activeColor: AppColors.accentBlue,
                    inactiveColor: AppColors.accentBlueDim,
                    label: '${clip.speed.toStringAsFixed(2)}x',
                    onChanged: (value) {
                      editorNotifier.setClipSpeed(clip.clipId, value);
                    },
                  ),
                  Text(
                    '${clip.speed.toStringAsFixed(2)}x',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.accentBlue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Video Settings
            _buildSection(
              context,
              'Video Settings',
              Icons.settings,
              Column(
                children: [
                  _buildInfoRow(
                    'Resolution',
                    '${metadata?.width ?? 'N/A'} x ${metadata?.height ?? 'N/A'}',
                  ),
                  _buildInfoRow(
                    'Frame Rate',
                    '${metadata?.frameRate.toStringAsFixed(2) ?? 'N/A'} fps',
                  ),
                  _buildInfoRow(
                    'Codec',
                    metadata?.codec ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Bitrate',
                    _formatBitrate(metadata?.bitrate ?? 0),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Position & Duration
            _buildSection(
              context,
              'Position & Duration',
              Icons.timeline,
              Column(
                children: [
                  _buildInfoRow('Start Time', _formatTime(clip.startTimeMs)),
                  _buildInfoRow('End Time', _formatTime(clip.endTimeMs)),
                  _buildInfoRow('Duration', _formatTime(clip.durationMs)),
                  _buildInfoRow('Track', '${clip.trackIndex}'),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Trimming (Future feature placeholder)
            _buildSection(
              context,
              'Trimming',
              Icons.content_cut,
              Column(
                children: [
                  _buildInfoRow('Trim Start', _formatTime(clip.trimStartMs)),
                  _buildInfoRow('Trim End', _formatTime(clip.trimEndMs)),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Use timeline handles to trim',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // NEW: Scale & Transform
            _buildSection(
              context,
              'Scale & Transform',
              Icons.aspect_ratio,
              Column(
                children: [
                  // Lock Aspect Ratio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lock Aspect Ratio',
                        style: AppTypography.bodyMedium,
                      ),
                      Switch(
                        value: clip.lockAspectRatio,
                        activeColor: AppColors.accentBlue,
                        onChanged: (value) {
                          editorNotifier.toggleClipAspectLock(clip.clipId);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Width Scale
                  _buildScaleControl(
                    'Width',
                    clip.scaleX,
                    (value) {
                      if (clip.lockAspectRatio) {
                        editorNotifier.setClipScale(clip.clipId, value, value);
                      } else {
                        editorNotifier.setClipScale(clip.clipId, value, clip.scaleY);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Height Scale
                  _buildScaleControl(
                    'Height',
                    clip.scaleY,
                    (value) {
                      if (clip.lockAspectRatio) {
                        editorNotifier.setClipScale(clip.clipId, value, value);
                      } else {
                        editorNotifier.setClipScale(clip.clipId, clip.scaleX, value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Reset Button
                  ElevatedButton.icon(
                    onPressed: () {
                      editorNotifier.setClipScale(clip.clipId, 1.0, 1.0);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset to 100%'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiaryBlack,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s, horizontal: AppSpacing.m),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      editorNotifier.splitClip(clip.clipId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Clip split successfully')),
                      );
                    },
                    icon: const Icon(Icons.content_cut),
                    label: const Text('Split'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      editorNotifier.removeClip(clip.clipId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Clip deleted')),
                      );
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accentBlue),
            const SizedBox(width: AppSpacing.s),
            Text(
              title,
              style: AppTypography.headingSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        content,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final ms = duration.inMilliseconds.remainder(1000) ~/ 10;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }

  String _formatBitrate(int bitrate) {
    if (bitrate == 0) return 'N/A';
    final mbps = bitrate / 1000000;
    return '${mbps.toStringAsFixed(2)} Mbps';
  }

  Widget _buildScaleControl(String label, double value, ValueChanged<double> onChanged) {
    final TextEditingController controller = TextEditingController(
      text: (value * 100).toStringAsFixed(0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlack,
                borderRadius: BorderRadius.circular(AppSpacing.radiusS),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffix: Text('%', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ),
                onSubmitted: (text) {
                  final percent = double.tryParse(text) ?? 100;
                  onChanged((percent / 100).clamp(0.01, 5.0));
                },
                onChanged: (text) {
                  // Update in real-time as user types
                  final percent = double.tryParse(text);
                  if (percent != null && percent >= 1 && percent <= 500) {
                    onChanged((percent / 100).clamp(0.01, 5.0));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Slider(
          value: value,
          min: 0.01,
          max: 5.0,
          divisions: 499,
          activeColor: AppColors.accentBlue,
          inactiveColor: AppColors.accentBlueDim,
          label: '${(value * 100).toStringAsFixed(0)}%',
          onChanged: (newValue) {
            controller.text = (newValue * 100).toStringAsFixed(0);
            onChanged(newValue);
          },
        ),
        // NEW: Show current value below slider
        Text(
          '${(value * 100).toStringAsFixed(0)}% ${value != 1.0 ? (value > 1.0 ? "(Zoomed)" : "(Shrunk)") : ""}',
          style: AppTypography.bodySmall.copyWith(
            color: value == 1.0 ? AppColors.textSecondary : AppColors.accentBlue,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

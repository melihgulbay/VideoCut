import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/editor_provider.dart';
import '../../native/video_engine_wrapper.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';

class AudioPropertiesPanel extends ConsumerWidget {
  final ClipData clip;

  const AudioPropertiesPanel({
    super.key,
    required this.clip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final editorNotifier = ref.read(editorProvider.notifier);
    final metadata = editorState.clipMetadata[clip.clipId];
    final waveform = editorState.clipWaveforms[clip.clipId];

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
                  Icons.audiotrack,
                  color: AppColors.trackAudio,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audio Properties',
                        style: AppTypography.headingMedium,
                      ),
                      Text(
                        'Audio ${clip.clipId}',
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

            // Waveform Preview
            if (waveform != null && waveform.isNotEmpty) ...[
              _buildSection(
                context,
                'Waveform',
                Icons.graphic_eq,
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlack,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: CustomPaint(
                    painter: _WaveformPainter(
                      waveformData: waveform,
                      color: AppColors.trackAudio,
                    ),
                    size: const Size(double.infinity, 80),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
            ],

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

            // Audio Settings
            _buildSection(
              context,
              'Audio Settings',
              Icons.settings,
              Column(
                children: [
                  _buildInfoRow(
                    'Channels',
                    '${metadata?.audioChannels ?? 'N/A'}',
                  ),
                  _buildInfoRow(
                    'Sample Rate',
                    '${metadata?.audioSampleRate ?? 'N/A'} Hz',
                  ),
                  _buildInfoRow(
                    'Format',
                    metadata?.codec ?? 'N/A',
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

            const SizedBox(height: AppSpacing.xl),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      editorNotifier.splitClip(clip.clipId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Audio clip split successfully')),
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
                        const SnackBar(content: Text('Audio clip deleted')),
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
}

// Waveform painter for audio visualization
class _WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;

  _WaveformPainter({
    required this.waveformData,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final centerY = size.height / 2;
    final barWidth = size.width / waveformData.length;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final amplitude = waveformData[i].clamp(0.0, 1.0);
      final barHeight = amplitude * (size.height / 2) * 0.9;

      canvas.drawLine(
        Offset(x, centerY - barHeight),
        Offset(x, centerY + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData ||
        oldDelegate.color != color;
  }
}

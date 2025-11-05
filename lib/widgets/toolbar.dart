import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/editor_provider.dart';
import '../export/export_wrapper.dart';
import '../native/video_engine_wrapper.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'common/studio_button.dart';
import '../export/export_dialog.dart';
import '../export/export_progress_dialog.dart';

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final editorNotifier = ref.read(editorProvider.notifier);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.secondaryBlack,
        border: Border(
          bottom: BorderSide(
            color: AppColors.dividerColor,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Row(
        children: [
          // Logo/Title Section
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusS),
                child: Image.asset(
                  'assets/images/flowcut.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'FlowCut',
                style: AppTypography.headingMedium,
              ),
            ],
          ),

          const SizedBox(width: AppSpacing.xl),

          // Import/Export Section
          StudioButton.primary(
            onPressed: () => _importVideo(context, ref),
            icon: Icons.file_upload,
            label: 'Import',
            size: StudioButtonSize.medium,
          ),

          const SizedBox(width: AppSpacing.s),

          StudioButton.secondary(
            onPressed: editorState.clips.isEmpty
                ? null
                : () => _exportVideo(context, ref),
            icon: Icons.file_download,
            label: 'Export',
            size: StudioButtonSize.medium,
          ),

          const SizedBox(width: AppSpacing.m),
          Container(width: 1, height: 32, color: AppColors.dividerColor),
          const SizedBox(width: AppSpacing.m),

          // Playback controls
          // Playback Controls
          _IconButton(
            icon: editorState.isPlaying ? Icons.pause : Icons.play_arrow,
            onPressed: editorState.clips.isEmpty
                ? () => _showMessage(context, 'No clips to play. Import a video first.')
                : () {
                    try {
                      if (editorState.isPlaying) {
                        editorNotifier.pause();
                      } else {
                        editorNotifier.play();
                      }
                    } catch (e) {
                      _showError(context, 'Playback failed: $e');
                    }
                  },
            tooltip: editorState.isPlaying ? 'Pause' : 'Play',
            isLarge: true,
          ),

          const SizedBox(width: AppSpacing.s),

          _IconButton(
            icon: Icons.skip_previous,
            onPressed: () {
              try {
                editorNotifier.seekTo(0);
              } catch (e) {
                _showError(context, 'Seek failed: $e');
              }
            },
            tooltip: 'Go to start',
          ),

          const SizedBox(width: AppSpacing.m),

          // Time display
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(editorState.currentTimeMs),
                  style: AppTypography.mono.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '/ ${_formatTime(editorState.timeline.getDuration())}',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.m),

          // Edit tools
          // Edit Tools
          _IconButton(
            icon: Icons.content_cut,
            onPressed: editorState.selectedClipId != null
                ? () {
                    try {
                      editorNotifier.splitClip(editorState.selectedClipId!);
                      _showMessage(context, 'Clip split successfully');
                    } catch (e) {
                      _showError(context, 'Split failed: $e');
                    }
                  }
                : () => _showMessage(context, 'Select a clip first to split it'),
            tooltip: 'Split clip',
          ),

          const SizedBox(width: AppSpacing.s),

          _IconButton(
            icon: Icons.delete_outline,
            onPressed: editorState.selectedClipId != null
                ? () {
                    try {
                      editorNotifier.removeClip(editorState.selectedClipId!);
                      _showMessage(context, 'Clip deleted');
                    } catch (e) {
                      _showError(context, 'Delete failed: $e');
                    }
                  }
                : () => _showMessage(context, 'Select a clip first to delete it'),
            tooltip: 'Delete clip',
          ),

          const SizedBox(width: AppSpacing.m),
          Container(width: 1, height: 32, color: AppColors.dividerColor),
          const SizedBox(width: AppSpacing.m),

          // Undo/Redo
          _IconButton(
            icon: Icons.undo,
            onPressed: editorNotifier.canUndo()
                ? () {
                    editorNotifier.undo();
                    _showMessage(context, 'Undo');
                  }
                : null,
            tooltip: 'Undo',
          ),

          const SizedBox(width: AppSpacing.s),

          _IconButton(
            icon: Icons.redo,
            onPressed: editorNotifier.canRedo()
                ? () {
                    editorNotifier.redo();
                    _showMessage(context, 'Redo');
                  }
                : null,
            tooltip: 'Redo',
          ),

          const SizedBox(width: AppSpacing.m),
          Container(width: 1, height: 32, color: AppColors.dividerColor),
          const SizedBox(width: AppSpacing.m),

          // Zoom Controls
          _IconButton(
            icon: Icons.zoom_out,
            onPressed: () {
              try {
                editorNotifier.setZoom(editorState.zoom / 1.5);
              } catch (e) {
                _showError(context, 'Zoom failed: $e');
              }
            },
            tooltip: 'Zoom out',
          ),

          const SizedBox(width: AppSpacing.s),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.tertiaryBlack,
              borderRadius: BorderRadius.circular(AppSpacing.radiusS),
              border: Border.all(color: AppColors.borderColor, width: 1),
            ),
            child: Text(
              '${(editorState.zoom * 100).toInt()}%',
              style: AppTypography.monoSmall,
            ),
          ),

          const SizedBox(width: AppSpacing.s),

          _IconButton(
            icon: Icons.zoom_in,
            onPressed: () {
              try {
                editorNotifier.setZoom(editorState.zoom * 1.5);
              } catch (e) {
                _showError(context, 'Zoom failed: $e');
              }
            },
            tooltip: 'Zoom in',
          ),

          const SizedBox(width: AppSpacing.m),
          Container(width: 1, height: 32, color: AppColors.dividerColor),
          const SizedBox(width: AppSpacing.m),

          // NEW: Snap toggle
          _IconButton(
            icon: Icons.grid_on,
            onPressed: () {
              editorNotifier.toggleSnap();
              _showMessage(
                context,
                editorState.snapEnabled ? 'Snap disabled' : 'Snap enabled',
              );
            },
            tooltip: editorState.snapEnabled ? 'Snap: ON' : 'Snap: OFF',
            isActive: editorState.snapEnabled,
          ),

          const SizedBox(width: AppSpacing.m),
          Container(width: 1, height: 32, color: AppColors.dividerColor),
          const SizedBox(width: AppSpacing.m),

          // NEW: Add Track button with dropdown
          PopupMenuButton<TrackType>(
            icon: const Icon(Icons.add_box, color: AppColors.textPrimary),
            tooltip: 'Add Track',
            color: AppColors.tertiaryBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
              side: BorderSide(color: AppColors.borderColor, width: 1),
            ),
            itemBuilder: (context) => [
              _buildTrackMenuItem(TrackType.text, Icons.text_fields, 'Text Track'),
              _buildTrackMenuItem(TrackType.video, Icons.videocam, 'Video Track'),
              _buildTrackMenuItem(TrackType.audio, Icons.audiotrack, 'Audio Track'),
            ],
            onSelected: (TrackType type) {
              if (editorState.tracks.length < 10) {
                editorNotifier.addTrackWithType(type);
                _showMessage(context, '${type.name.toUpperCase()} track added');
              } else {
                _showMessage(context, 'Maximum 10 tracks reached', isWarning: true);
              }
            },
          ),

          // Track Count
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.tertiaryBlack,
              borderRadius: BorderRadius.circular(AppSpacing.radiusS),
              border: Border.all(color: AppColors.borderColor, width: 1),
            ),
            child: Text(
              '${editorState.tracks.length} tracks',
              style: AppTypography.labelSmall,
            ),
          ),

          const SizedBox(width: AppSpacing.m),
          Container(width: 1, height: 32, color: AppColors.dividerColor),
          const SizedBox(width: AppSpacing.m),

          // NEW: Add Text Layer button
          _IconButton(
            icon: Icons.text_fields,
            onPressed: () {
              editorNotifier.addTextLayer();
              _showMessage(context, 'Text layer added');
            },
            tooltip: 'Add Text',
          ),
        ],
      ),
    );
  }

  PopupMenuItem<TrackType> _buildTrackMenuItem(TrackType type, IconData icon, String label) {
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.s),
          Text(label, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Future<void> _importVideo(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          // Video formats
          'mp4',
          'mov',
          'avi',
          'mkv',
          'flv',
          'wmv',
          'webm',
          'm4v',
          '3gp',
          // Audio formats
          'mp3',
          'wav',
          'aac',
          'm4a',
          'flac',
          'ogg',
          'wma',
          'opus',
        ],
        allowMultiple: true,
        dialogTitle: 'Import Video or Audio Files',
      );

      if (result != null && result.files.isNotEmpty) {
        final editorNotifier = ref.read(editorProvider.notifier);
        final editorState = ref.read(editorProvider);

        // Auto-create tracks if none exist
        if (editorState.tracks.isEmpty) {
          // Create initial tracks based on what's being imported
          final hasVideo = result.files.any((file) {
            final ext = file.extension?.toLowerCase() ?? '';
            return !['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg', 'wma', 'opus']
                .contains(ext);
          });

          final hasAudio = result.files.any((file) {
            final ext = file.extension?.toLowerCase() ?? '';
            return ['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg', 'wma', 'opus']
                .contains(ext);
          });

          // Create tracks in order: Text (if needed), Video, Audio
          if (hasVideo) {
            editorNotifier.addTrackWithType(TrackType.video);
          }
          if (hasAudio || hasVideo) {
            // Always create audio track if importing media (for video audio extraction)
            editorNotifier.addTrackWithType(TrackType.audio);
          }

          // Reload state after creating tracks
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Get updated state after track creation
        final updatedState = ref.read(editorProvider);

        // Find appropriate tracks
        final videoTrack = updatedState.tracks.firstWhere(
          (t) => t.trackType == TrackType.video,
          orElse: () {
            // If no video track, create one
            editorNotifier.addTrackWithType(TrackType.video);
            return updatedState.tracks.last;
          },
        );
        final audioTrack = updatedState.tracks.firstWhere(
          (t) => t.trackType == TrackType.audio,
          orElse: () {
            // If no audio track, create one
            editorNotifier.addTrackWithType(TrackType.audio);
            return updatedState.tracks.last;
          },
        );

        for (final file in result.files) {
          if (file.path != null) {
            // Determine if file is audio-only
            final ext = file.extension?.toLowerCase() ?? '';
            final isAudioFile = ['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg', 'wma', 'opus']
                .contains(ext);

            // Add to appropriate track
            final targetTrackId = isAudioFile ? audioTrack.trackId : videoTrack.trackId;
            await editorNotifier.addClip(file.path!, trackIndex: targetTrackId);
          }
        }

        if (!context.mounted) return;
        _showMessage(context, '${result.files.length} file(s) imported');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Import failed: $e');
    }
  }

  Future<void> _exportVideo(BuildContext context, WidgetRef ref) async {
    try {
      final editorNotifier = ref.read(editorProvider.notifier);
      editorNotifier.syncTextLayersToNative();

      final settings = await showDialog<ExportSettingsData>(
        context: context,
        builder: (context) => const ExportDialog(),
      );

      if (settings == null) return;

      final exporter = VideoExporter();
      final editorState = ref.read(editorProvider);

      final started = await exporter.startExport(
        editorState.timeline,
        settings,
      );

      if (!started) {
        if (!context.mounted) return;
        _showError(context, 'Failed to start export');
        exporter.dispose();
        return;
      }

      if (!context.mounted) return;
      final completed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ExportProgressDialog(
          exporter: exporter,
          onComplete: () {
            _showMessage(context, 'Video exported successfully!');
          },
          onCancel: () {
            _showMessage(context, 'Export cancelled', isWarning: true);
          },
        ),
      );

      exporter.dispose();

      if (completed == true && context.mounted) {
        _showMessage(context, 'Export completed successfully!');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Export failed: $e');
    }
  }

  void _showMessage(BuildContext context, String message, {bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isWarning ? AppColors.warningOrange : AppColors.tertiaryBlack,
      duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
 backgroundColor: AppColors.errorRed,
        duration: const Duration(seconds: 3),
     action: SnackBarAction(
          label: 'Dismiss',
          textColor: AppColors.textPrimary,
   onPressed: () {},
    ),
      ),
  );
  }

  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final frames = (duration.inMilliseconds.remainder(1000) / 33.33).floor();

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${frames.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${frames.toString().padLeft(2, '0')}';
  }
}

/// Custom icon button with hover effect for toolbar
class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isLarge;
  final bool isActive;
  
  const _IconButton({
    required this.icon,
required this.onPressed,
    required this.tooltip,
    this.isLarge = false,
    this.isActive = false,
  });

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final size = widget.isLarge ? 40.0 : 32.0;
    final iconSize = widget.isLarge ? AppSpacing.iconL : AppSpacing.iconM;
    
    return Tooltip(
      message: widget.tooltip,
   child: MouseRegion(
  onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
   onTap: widget.onPressed,
          child: AnimatedContainer(
 duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
decoration: BoxDecoration(
         color: widget.isActive 
         ? AppColors.accentBlueDim
            : (_isHovered && !isDisabled ? AppColors.hoverOverlay : Colors.transparent),
 borderRadius: BorderRadius.circular(AppSpacing.radiusM),
     ),
            child: Icon(
              widget.icon,
              size: iconSize,
              color: isDisabled 
      ? AppColors.textTertiary
    : (widget.isActive ? AppColors.accentBlue : AppColors.textPrimary),
      ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'dart:async';
import '../providers/editor_provider.dart';
import '../models/text_layer_data.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../theme/shadows.dart';
import 'interactive_video_frame.dart'; // NEW

// Aspect ratio presets for different platforms
enum AspectRatioPreset {
  widescreen('16:9', 16 / 9),      // YouTube, TV
  vertical('9:16', 9 / 16),     // TikTok, Instagram Reels
  square('1:1', 1.0),            // Instagram Post
  standard('4:3', 4 / 3),          // Old TV
  ultrawide('21:9', 21 / 9),       // Cinematic
  custom('Custom', null);    // User-defined

  final String label;
  final double? ratio;
  const AspectRatioPreset(this.label, this.ratio);
}

// Video quality presets
enum VideoQuality {
  quality2160p('2160p (4K)', 2160),
  quality1080p('1080p (FHD)', 1080),
  quality720p('720p (HD)', 720),
  quality480p('480p (SD)', 480),
  custom('Custom', null);          // User-defined

  final String label;
  final int? height;
  const VideoQuality(this.label, this.height);
}

class VideoPreview extends ConsumerStatefulWidget {
  const VideoPreview({super.key});

  @override
  ConsumerState<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends ConsumerState<VideoPreview> {
  ui.Image? _displayImage;
  bool _isRendering = false;
  int _lastRenderedTime = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFrame());
  }

  Future<void> _updateFrame() async {
    try {
      final editorState = ref.read(editorProvider);
      final currentTime = editorState.currentTimeMs;
      
      if (editorState.clips.isEmpty) {
   if (mounted && _displayImage != null) {
          setState(() {
    _displayImage?.dispose();
        _displayImage = null;
      _isRendering = false;
      });
        }
     return;
      }
      
  if (_isRendering || currentTime == _lastRenderedTime) {
        return;
      }
  
      setState(() => _isRendering = true);
      _lastRenderedTime = currentTime;

      // Check if there are any active video clips at current time
      final hasActiveClips = editorState.clips.any((clip) =>
        currentTime >= clip.startTimeMs && currentTime < clip.endTimeMs && !clip.isAudioOnly);

      if (!hasActiveClips) {
        if (mounted) {
   setState(() {
   _displayImage?.dispose();
   _displayImage = null;
            _isRendering = false;
       });
   }
        return;
  }

      // Use same renderer as export for consistency
      final width = editorState.previewWidth;
      final height = editorState.previewHeight;
      
   debugPrint('PREVIEW: Rendering frame at ${currentTime}ms (${width}x${height})');

      final frameBytes = editorState.timeline.renderFrameEx(
        currentTime,
   width: width,
        height: height,
 supersample: 1, // Standard quality - same as export
      );

      if (frameBytes == null || frameBytes.isEmpty) {
        debugPrint('PREVIEW: No frame data returned');
        if (mounted) setState(() => _isRendering = false);
        return;
      }

      debugPrint('PREVIEW: Got frame data, ${frameBytes.length} bytes');
  
      // Validate frame size
      final expectedSize = width * height * 4;
      if (frameBytes.length != expectedSize) {
        debugPrint('PREVIEW: ERROR: Frame size mismatch! Expected: $expectedSize, got: ${frameBytes.length}');
        if (mounted) setState(() => _isRendering = false);
        return;
      }
  
      debugPrint('PREVIEW: Decoding image from pixels...');
      final completer = Completer<ui.Image>();
   
      ui.decodeImageFromPixels(
        frameBytes,
        width,
        height,
        ui.PixelFormat.rgba8888,
        (ui.Image image) {
          debugPrint('PREVIEW: Image decoded successfully');
      if (!completer.isCompleted) completer.complete(image);
     },
   );
    
      final image = await completer.future.timeout(
        const Duration(seconds: 2),
     onTimeout: () {
          debugPrint('PREVIEW: ERROR: Decode timeout!');
     throw TimeoutException('Decode timeout');
        },
      );
    
      if (mounted) {
        setState(() {
   _displayImage?.dispose();
     _displayImage = image;
          _isRendering = false;
        });
   debugPrint('PREVIEW: Frame updated successfully');
      }
    } catch (e, stackTrace) {
      debugPrint('PREVIEW: ERROR in _updateFrame: $e');
  debugPrint('PREVIEW: Stack trace: $stackTrace');
      if (mounted) setState(() => _isRendering = false);
    }
  }

  @override
  void dispose() {
    _displayImage?.dispose();
    super.dispose();
  }
  
  // Show custom resolution dialog
  Future<Map<String, int>?> _showCustomResolutionDialog(BuildContext context, WidgetRef ref) async {
    final state = ref.read(editorProvider);
    final widthController = TextEditingController(text: state.customWidth.toString());
    final heightController = TextEditingController(text: state.customHeight.toString());
    
    return showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          side: BorderSide(color: AppColors.borderColor, width: 1),
        ),
        title: Text(
'Custom Resolution',
   style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary),
        ),
      content: Column(
          mainAxisSize: MainAxisSize.min,
  children: [
        TextField(
    controller: widthController,
     keyboardType: TextInputType.number,
         style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
      labelText: 'Width',
 labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
     filled: true,
     fillColor: AppColors.primaryBlack,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusM),
     borderSide: BorderSide(color: AppColors.borderColor),
        ),
         enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
      borderSide: BorderSide(color: AppColors.borderColor),
      ),
   focusedBorder: OutlineInputBorder(
       borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
         ),
          ),
      ),
            const SizedBox(height: AppSpacing.m),
            TextField(
     controller: heightController,
        keyboardType: TextInputType.number,
    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
  labelText: 'Height',
                labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
           filled: true,
           fillColor: AppColors.primaryBlack,
 border: OutlineInputBorder(
       borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
       enabledBorder: OutlineInputBorder(
     borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        borderSide: BorderSide(color: AppColors.borderColor),
       ),
          focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusM),
     borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
 ),
     ),
            ),
 ],
        ),
    actions: [
    TextButton(
       onPressed: () => Navigator.pop(context),
      child: Text(
   'Cancel',
           style: AppTypography.buttonMedium.copyWith(color: AppColors.textSecondary),
      ),
  ),
      ElevatedButton(
   onPressed: () {
      final width = int.tryParse(widthController.text) ?? 1920;
      final height = int.tryParse(heightController.text) ?? 1080;
              Navigator.pop(context, {'width': width, 'height': height});
       },
   style: ElevatedButton.styleFrom(
 backgroundColor: AppColors.accentBlue,
      foregroundColor: AppColors.textPrimary,
         shape: RoundedRectangleBorder(
       borderRadius: BorderRadius.circular(AppSpacing.radiusM),
              ),
  ),
        child: Text('Apply', style: AppTypography.buttonMedium),
),
     ],
      ),
);
  }

  @override
  Widget build(BuildContext context) {
    final currentTime = ref.watch(editorProvider.select((s) => s.currentTimeMs));
  final clips = ref.watch(editorProvider.select((s) => s.clips));
    final textLayers = ref.watch(editorProvider.select((s) => s.textLayers));
    final state = ref.watch(editorProvider);
    final selectedClipId = ref.watch(editorProvider.select((s) => s.selectedClipId));

  WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFrame();
    });

 if (clips.isEmpty) {
  return _buildModernContainer(
     child: _EmptyState(
 hasClips: false,
  isRendering: false,
duration: 0,
      clipCount: 0,
     ),
      );
    }

    final selectedClip = selectedClipId != null
  ? clips.firstWhere((c) => c.clipId == selectedClipId, orElse: () => clips.first)
: null;

    // Calculate preview aspect ratio from export settings
    final previewAspectRatio = state.exportWidth / state.exportHeight;

    return _buildModernContainer(
 child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate preview container dimensions to fit aspect ratio
          double containerWidth, containerHeight;
 
 if (constraints.maxWidth / constraints.maxHeight > previewAspectRatio) {
            // Available space is wider than aspect ratio - fit to height
     containerHeight = constraints.maxHeight;
    containerWidth = containerHeight * previewAspectRatio;
  } else {
   // Available space is taller than aspect ratio - fit to width
          containerWidth = constraints.maxWidth;
      containerHeight = containerWidth / previewAspectRatio;
      }

      return Stack(
        children: [
 // Centered preview container with correct aspect ratio
         Center(
             child: Container(
         width: containerWidth,
  height: containerHeight,
      decoration: BoxDecoration(
      border: Border.all(
           color: selectedClipId != null ? AppColors.accentBlue : AppColors.borderColor,
        width: selectedClipId != null ? 3 : 2,
       ),
          color: AppColors.primaryBlack,
          ),
   child: Stack(
          fit: StackFit.expand,
           children: [
    // Video frame
     if (_displayImage != null)
       selectedClipId != null && selectedClip != null && !selectedClip.isAudioOnly
 ? InteractiveVideoFrame(
    frame: _displayImage,
  selectedClip: selectedClip,
      containerSize: Size(containerWidth, containerHeight),
     )
      : CustomPaint(
 painter: _FramePainter(_displayImage!),
         size: Size.infinite,
 ),

   // Empty state message
   if (_displayImage == null && !_isRendering)
  Center(
 child: Text(
 'No clips at this position',
   style: AppTypography.bodyMedium.copyWith(
    color: AppColors.textTertiary,
),
    ),
       ),

     // Loading indicator
 if (_isRendering)
          Center(
 child: CircularProgressIndicator(
  color: AppColors.accentBlue,
 strokeWidth: 3,
   ),
  ),
        ],
                  ),
       ),
         ),

   // Aspect Ratio Selector (top-left)
     Positioned(
            top: AppSpacing.m,
   left: AppSpacing.m,
  child: _AspectRatioSelector(
 selected: state.aspectRatio,
        onChanged: (ratio) async {
        if (ratio == AspectRatioPreset.custom) {
                  final result = await _showCustomResolutionDialog(context, ref);
   if (result != null) {
     ref.read(editorProvider.notifier).setCustomResolution(
  result['width']!,
     result['height']!,
);
 }
} else {
      ref.read(editorProvider.notifier).setAspectRatio(ratio);
      }
     },
   ),
 ),

 // Quality Selector (top-left, below aspect ratio)
        Positioned(
 top: AppSpacing.m + 40,
      left: AppSpacing.m,
            child: _QualitySelector(
     selected: state.quality,
           onChanged: (quality) async {
         if (quality == VideoQuality.custom) {
        final result = await _showCustomResolutionDialog(context, ref);
    if (result != null) {
    ref.read(editorProvider.notifier).setCustomResolution(
   result['width']!,
    result['height']!,
         );
  }
     } else {
   ref.read(editorProvider.notifier).setQuality(quality);
       }
            },
   ),
  ),

 // Resolution badge (top-right)
       if (_displayImage != null)
     Positioned(
 top: AppSpacing.m,
      right: AppSpacing.m,
child: _ResolutionBadge(
  width: state.exportWidth,
 height: state.exportHeight,
 aspectRatio: state.aspectRatio.label,
   quality: state.quality.label,
        ),
  ),
   ],
      );
      },
      ),
  );
  }
  
  /// Modern container with rounded corners and shadow
  Widget _buildModernContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        boxShadow: AppShadows.medium,
     border: Border.all(
     color: AppColors.borderColor,
   width: 1,
        ),
    ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Aspect ratio selector dropdown
class _AspectRatioSelector extends StatelessWidget {
  final AspectRatioPreset selected;
  final Function(AspectRatioPreset) onChanged;

  const _AspectRatioSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
     vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.blackOverlay75,
 borderRadius: BorderRadius.circular(AppSpacing.radiusS),
      border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
  ),
 ),
      child: PopupMenuButton<AspectRatioPreset>(
    initialValue: selected,
        tooltip: 'Aspect Ratio',
     color: AppColors.tertiaryBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusM),
     side: BorderSide(color: AppColors.borderColor, width: 1),
 ),
        offset: const Offset(0, 40),
        child: Row(
    mainAxisSize: MainAxisSize.min,
   children: [
            Icon(
   Icons.aspect_ratio,
         size: 16,
    color: AppColors.textPrimary,
      ),
 const SizedBox(width: AppSpacing.xs),
            Text(
      selected.label,
   style: AppTypography.labelSmall.copyWith(
        color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
     ),
            ),
    const SizedBox(width: AppSpacing.xs),
    Icon(
        Icons.arrow_drop_down,
       size: 16,
    color: AppColors.textSecondary,
      ),
   ],
        ),
        itemBuilder: (context) => AspectRatioPreset.values.map((preset) {
 return PopupMenuItem<AspectRatioPreset>(
value: preset,
   child: Row(
              children: [
     Icon(
        preset == selected ? Icons.check : Icons.crop_free,
  size: 18,
          color: preset == selected ? AppColors.accentBlue : AppColors.textSecondary,
     ),
      const SizedBox(width: AppSpacing.s),
     Text(
 preset.label,
 style: AppTypography.bodyMedium.copyWith(
    color: preset == selected ? AppColors.accentBlue : AppColors.textPrimary,
      fontWeight: preset == selected ? FontWeight.w600 : FontWeight.normal,
      ),
        ),
     ],
 ),
     );
     }).toList(),
        onSelected: onChanged,
 ),
    );
  }
}

/// Quality selector dropdown
class _QualitySelector extends StatelessWidget {
  final VideoQuality selected;
  final Function(VideoQuality) onChanged;

  const _QualitySelector({
  required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
 padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
 vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.blackOverlay75,
        borderRadius: BorderRadius.circular(AppSpacing.radiusS),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
      ),
      ),
      child: PopupMenuButton<VideoQuality>(
        initialValue: selected,
        tooltip: 'Quality',
 color: AppColors.tertiaryBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusM),
          side: BorderSide(color: AppColors.borderColor, width: 1),
        ),
        offset: const Offset(0, 40),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
       Icon(
 Icons.high_quality,
      size: 16,
         color: AppColors.textPrimary,
     ),
            const SizedBox(width: AppSpacing.xs),
      Text(
       selected.label,
         style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
fontWeight: FontWeight.w600,
        ),
         ),
            const SizedBox(width: AppSpacing.xs),
         Icon(
         Icons.arrow_drop_down,
            size: 16,
        color: AppColors.textSecondary,
          ),
          ],
        ),
        itemBuilder: (context) => VideoQuality.values.map((quality) {
          return PopupMenuItem<VideoQuality>(
  value: quality,
            child: Row(
     children: [
     Icon(
      quality == selected ? Icons.check : Icons.hd,
       size: 18,
   color: quality == selected ? AppColors.accentBlue : AppColors.textSecondary,
      ),
          const SizedBox(width: AppSpacing.s),
      Text(
       quality.label,
      style: AppTypography.bodyMedium.copyWith(
        color: quality == selected ? AppColors.accentBlue : AppColors.textPrimary,
        fontWeight: quality == selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
         ],
            ),
  );
        }).toList(),
      onSelected: onChanged,
   ),
    );
  }
}

/// Resolution badge overlay
class _ResolutionBadge extends StatelessWidget {
  final int width;
  final int height;
final String aspectRatio;
  final String quality;

  const _ResolutionBadge({
required this.width,
  required this.height,
    required this.aspectRatio,
    required this.quality,
});

  @override
  Widget build(BuildContext context) {
    return Container(
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
        color: AppColors.blackOverlay75,
    borderRadius: BorderRadius.circular(AppSpacing.radiusS),
        border: Border.all(
       color: AppColors.borderColor.withOpacity(0.3),
   width: 1,
),
      ),
    child: Column(
   mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.end,
 children: [
    // Resolution
    Text(
   '${width}x$height',
       style: AppTypography.labelSmall.copyWith(
        color: AppColors.textPrimary,
   fontWeight: FontWeight.w600,
  ),
      ),
        // Aspect ratio
 Text(
  aspectRatio,
      style: AppTypography.bodySmall.copyWith(
         color: AppColors.accentBlue,
 fontSize: 10,
         ),
    ),
       // Quality
          Text(
     quality,
            style: AppTypography.bodySmall.copyWith(
        color: AppColors.textSecondary,
 fontSize: 10,
    ),
          ),
   ],
   ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasClips;
  final bool isRendering;
  final int duration;
  final int clipCount;

  const _EmptyState({
    required this.hasClips,
    required this.isRendering,
    required this.duration,
    required this.clipCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryBlack,
      child: Center(
        child: Column(
     mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
          children: [
            if (isRendering)
         CircularProgressIndicator(
                color: AppColors.accentBlue,
     strokeWidth: 3,
        )
      else
  Container(
                padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
          color: AppColors.secondaryBlack,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
      border: Border.all(
             color: AppColors.borderColor,
          width: 1,
      ),
           ),
            child: Icon(
              hasClips ? Icons.videocam_off_outlined : Icons.video_library_outlined,
                size: 64,
           color: AppColors.textTertiary,
     ),
              ),
            const SizedBox(height: AppSpacing.l),
         Text(
       isRendering
          ? 'Rendering...'
         : hasClips
             ? 'Click Play or seek to view'
   : 'No video',
    textAlign: TextAlign.center,
     style: AppTypography.headingSmall.copyWith(
        color: isRendering ? AppColors.accentBlue : AppColors.textSecondary,
      ),
       ),
    const SizedBox(height: AppSpacing.s),
            if (!isRendering && !hasClips)
  Text(
                'Click "Import" to add media',
        style: AppTypography.bodySmall.copyWith(
      color: AppColors.textTertiary,
      ),
 ),
            if (hasClips && !isRendering) ...[
              const SizedBox(height: AppSpacing.l),
 _StatusCard(clipCount: clipCount, duration: duration),
        ],
      ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final int clipCount;
  final int duration;

  const _StatusCard({required this.clipCount, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
    padding: const EdgeInsets.symmetric(
  horizontal: AppSpacing.m,
     vertical: AppSpacing.s,
   ),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBlack,
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
   ),
      child: Row(
      mainAxisSize: MainAxisSize.min,
        children: [
   Icon(
     Icons.movie_outlined,
     size: AppSpacing.iconM,
   color: AppColors.accentBlue,
          ),
          const SizedBox(width: AppSpacing.s),
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
       mainAxisSize: MainAxisSize.min,
      children: [
   Text(
         '$clipCount clip${clipCount > 1 ? 's' : ''}',
  style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textPrimary,
   ),
        ),
       Text(
       _formatDuration(duration),
         style: AppTypography.bodySmall.copyWith(
       color: AppColors.textSecondary,
       ),
    ),
       ],
  ),
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    return '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}

class _FramePainter extends CustomPainter {
  final ui.Image image;

  const _FramePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final imageAspect = image.width / image.height;
    final containerAspect = size.width / size.height;

    double drawWidth, drawHeight, offsetX = 0, offsetY = 0;

    if (imageAspect > containerAspect) {
      drawWidth = size.width;
      drawHeight = size.width / imageAspect;
      offsetY = (size.height - drawHeight) / 2;
    } else {
      drawHeight = size.height;
    drawWidth = size.height * imageAspect;
      offsetX = (size.width - drawWidth) / 2;
    }

    final destRect = Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight);
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    canvas.drawImageRect(image, srcRect, destRect, Paint());
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => oldDelegate.image != image;
}
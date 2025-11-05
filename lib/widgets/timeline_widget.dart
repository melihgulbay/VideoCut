import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../native/video_engine_wrapper.dart';
import '../providers/editor_provider.dart';
import '../models/text_layer_data.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../theme/shadows.dart';

class TimelineWidget extends ConsumerStatefulWidget {
  final List<ClipData> clips;
  final int currentTimeMs;
  final int? selectedClipId;
  final double zoom;
  final int scrollOffset;
  final Map<int, List<double>> clipWaveforms;
  final int trackCount;
  final List<TextLayerData> textLayers;  // NEW
  final int? selectedTextLayerId;  // NEW
  final List<TrackData> tracks;  // NEW: Track metadata
  final Function(int) onSeek;
  final Function(int?) onClipSelect;
  final Function(int, int) onClipMove;
  final Function(int, int) onClipChangeTrack;
  final Function(double) onZoomChange;
  final Function(int) onScroll;
  final Function(int?) onTextLayerSelect;  // NEW
  final Function(int, int) onTextLayerMove;  // NEW

  const TimelineWidget({
    super.key,
    required this.clips,
    required this.currentTimeMs,
    required this.selectedClipId,
    required this.zoom,
    required this.scrollOffset,
    required this.clipWaveforms,
    this.trackCount = 3,
    this.textLayers = const [],  // NEW
    this.selectedTextLayerId,  // NEW
    this.tracks = const [],  // NEW: Default empty list
    required this.onSeek,
    required this.onClipSelect,
    required this.onClipMove,
    required this.onClipChangeTrack,
    required this.onZoomChange,
    required this.onScroll,
    required this.onTextLayerSelect,  // NEW
    required this.onTextLayerMove,  // NEW
  });

  @override
  ConsumerState<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends ConsumerState<TimelineWidget> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _rulerScrollController = ScrollController();
  final ScrollController _trackScrollController = ScrollController();  // NEW: Vertical scroll
  final int _trackHeight = 60;
  // Remove fixed _trackCount, use widget.trackCount instead

  @override
  void initState() {
    super.initState();
    // Sync both scroll controllers
    _scrollController.addListener(() {
      if (_scrollController.hasClients && _rulerScrollController.hasClients) {
        if (_scrollController.offset != _rulerScrollController.offset) {
          _rulerScrollController.jumpTo(_scrollController.offset);
        }
        widget.onScroll(_scrollController.offset.toInt());
      }
    });

    _rulerScrollController.addListener(() {
      if (_scrollController.hasClients && _rulerScrollController.hasClients) {
        if (_rulerScrollController.offset != _scrollController.offset) {
   _scrollController.jumpTo(_rulerScrollController.offset);
   }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rulerScrollController.dispose();
    _trackScrollController.dispose();  // NEW: Dispose vertical scroll
    super.dispose();
  }

  double _timeToX(int timeMs) {
    return (timeMs / 1000.0) * 100 * widget.zoom;
  }

  int _xToTime(double x) {
    return ((x / (100 * widget.zoom)) * 1000).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
   color: AppColors.secondaryBlack,
        border: Border(
    top: BorderSide(
        color: AppColors.dividerColor,
      width: 1,
      ),
   ),
      ),
      child: Column(
   children: [
   // Timeline header with time ruler
        _buildTimeRuler(),

          // Tracks with vertical scrollbar
Expanded(
      child: Stack(
  children: [
    // Scrollable track area
    SingleChildScrollView(
       controller: _trackScrollController,
  scrollDirection: Axis.vertical,
     child: SizedBox(
 height: _trackHeight * widget.tracks.length.toDouble(),  // Use tracks length
         child: Stack(
     children: [
         // Track backgrounds
     _buildTracks(),

   // Clips
   SingleChildScrollView(
          controller: _scrollController,
      scrollDirection: Axis.horizontal,
    child: SizedBox(
 height: _trackHeight * widget.tracks.length.toDouble(),  // Use tracks length
         width: _timeToX(60000 * 10), // 10 minutes max
      child: Stack(
   children: [
          // Render clips
         ...widget.clips.map((clip) => _buildClip(clip)),
         // Render text layers on their tracks
      ...widget.textLayers.map((layer) => _buildTextLayerOnTrack(layer)),
                ],
       ),
     ),
    ),
    ],
),
  ),
     ),

  // Playhead (overlaid on top)
    _buildPlayhead(),
          ],
    ),
 ),
        ],
      ),
    );
  }

  Widget _buildTimeRuler() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
color: AppColors.tertiaryBlack,
 border: Border(
      bottom: BorderSide(
            color: AppColors.dividerColor,
      width: 1,
     ),
   ),
 ),
      child: GestureDetector(
    onTapDown: (details) {
      // Calculate time from tap position
   final scrollOffset = _rulerScrollController.hasClients
     ? _rulerScrollController.offset
  : 0.0;
   final tapX = details.localPosition.dx + scrollOffset;
   final timeMs = _xToTime(tapX);
    widget.onSeek(timeMs);
 },
    child: SingleChildScrollView(
   controller: _rulerScrollController,
    scrollDirection: Axis.horizontal,
    child: SizedBox(
   width: _timeToX(60000 * 10),
            child: CustomPaint(
              painter: TimeRulerPainter(zoom: widget.zoom),
   ),
      ),
   ),
      ),
    );
  }

  Widget _buildTracks() {
    final sortedTracks = [...widget.tracks]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    
 return Column(
   children: sortedTracks.map((track) {
   final trackColor = _getTrackColor(track.trackType);
        final trackIndex = sortedTracks.indexOf(track);
        
        return GestureDetector(
     onSecondaryTapDown: (details) => _showTrackContextMenu(context, details, track, trackIndex),
          child: Container(
     height: _trackHeight.toDouble(),
  decoration: BoxDecoration(
       border: Border(
      bottom: BorderSide(color: AppColors.dividerColor, width: 1),
 ),
   color: trackColor,
        ),
        child: Padding(
padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.s,
       vertical: AppSpacing.xs,
 ),
     child: Row(
  children: [
      Container(
             width: 3,
    height: 24,
      decoration: BoxDecoration(
          color: _getTrackAccentColor(track.trackType),
 borderRadius: BorderRadius.circular(2),
       ),
        ),
          const SizedBox(width: AppSpacing.s),
   Icon(
  _getTrackIcon(track.trackType),
      size: 16,
    color: AppColors.textSecondary,
        ),
      const SizedBox(width: AppSpacing.s),
   Expanded(
     child: Text(
     track.trackName,
     style: AppTypography.labelSmall.copyWith(
      color: AppColors.textSecondary,
    ),
    ),
    ),
       if (!track.isVisible)
           Icon(Icons.visibility_off, size: 16, color: AppColors.textTertiary),
     if (track.isLocked)
                  const SizedBox(width: AppSpacing.xs),
  if (track.isLocked)
  Icon(Icons.lock, size: 16, color: AppColors.textTertiary),
],
       ),
   ),
    ),
   );
      }).toList(),
    );
  }

  Color _getTrackColor(TrackType trackType) {
    switch (trackType) {
      case TrackType.video:
   return AppColors.primaryBlack;
      case TrackType.audio:
   return AppColors.secondaryBlack.withOpacity(0.5);
  case TrackType.text:
        return AppColors.primaryBlack.withOpacity(0.8);
      case TrackType.overlay:
   return AppColors.primaryBlack.withOpacity(0.9);
    }
  }

  Color _getTrackAccentColor(TrackType trackType) {
    switch (trackType) {
      case TrackType.video:
      return AppColors.trackVideo;
      case TrackType.audio:
        return AppColors.trackAudio;
      case TrackType.text:
        return AppColors.trackText;
      case TrackType.overlay:
        return AppColors.accentBlue;
    }
  }

  IconData _getTrackIcon(TrackType trackType) {
    switch (trackType) {
      case TrackType.video:
   return Icons.videocam;
      case TrackType.audio:
        return Icons.audiotrack;
      case TrackType.text:
    return Icons.text_fields;
case TrackType.overlay:
   return Icons.layers;
    }
  }

  void _showTrackContextMenu(BuildContext context, TapDownDetails details, TrackData track, int visualIndex) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu<String>(
      context: context,
  position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
  Offset.zero & overlay.size,
    ),
      items: <PopupMenuEntry<String>>[
  if (visualIndex > 0)
       PopupMenuItem<String>(
    value: 'swap_up',
      child: const Row(
    children: [
     Icon(Icons.arrow_upward, size: 18),
      SizedBox(width: 8),
    Text('Move Up'),
            ],
    ),
   ),
        if (visualIndex < widget.tracks.length - 1)
  PopupMenuItem<String>(
    value: 'swap_down',
      child: const Row(
      children: [
        Icon(Icons.arrow_downward, size: 18),
  SizedBox(width: 8),
      Text('Move Down'),
        ],
     ),
      ),
const PopupMenuDivider(),
        PopupMenuItem<String>(
    value: 'delete',
   enabled: !_hasClipsOnTrack(track.trackId),
  child: Row(
  children: [
         Icon(Icons.delete, size: 18, color: _hasClipsOnTrack(track.trackId) ? Colors.grey : Colors.red),
   const SizedBox(width: 8),
           Text('Delete Track', style: TextStyle(color: _hasClipsOnTrack(track.trackId) ? Colors.grey : Colors.red)),
       ],
),
        ),
 ],
    ).then((value) {
      if (value == null) return;
   
      final ref = ProviderScope.containerOf(context);
   final editorNotifier = ref.read(editorProvider.notifier);
      
  switch (value) {
  case 'swap_up':
          final otherTrack = widget.tracks[visualIndex - 1];
 editorNotifier.swapTrackPositions(track.trackId, otherTrack.trackId);
     break;
     case 'swap_down':
     final otherTrack = widget.tracks[visualIndex + 1];
 editorNotifier.swapTrackPositions(track.trackId, otherTrack.trackId);
       break;
  case 'delete':
  editorNotifier.removeTrackById(track.trackId);
          break;
      }
 });
  }

  bool _hasClipsOnTrack(int trackId) {
    return widget.clips.any((clip) => clip.trackIndex == trackId);
  }
  
  Widget _buildClip(ClipData clip) {
    final x = _timeToX(clip.startTimeMs);
    final width = _timeToX(clip.durationMs);
  
    // IMPORTANT: Sort tracks the same way as _buildTracks() does
    final sortedTracks = [...widget.tracks]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    
    // Find track by matching clip.trackIndex to track.trackId IN THE SORTED LIST
    final trackIndex = sortedTracks.indexWhere((t) => t.trackId == clip.trackIndex);
    if (trackIndex == -1) return const SizedBox.shrink();  // Clip on non-existent track
    
    final track = sortedTracks[trackIndex];
    
  // Don't render if track is invisible
    if (!track.isVisible) return const SizedBox.shrink();
    
    final y = trackIndex * _trackHeight.toDouble();
 final isSelected = clip.clipId == widget.selectedClipId;
    
    // Get original duration for this clip from the provider
 final editorState = ref.watch(editorProvider);
    final originalDuration = editorState.originalDurations[clip.clipId] ?? clip.trimEndMs;

    return Positioned(
   left: x,
  top: y + 4,
   width: width,
    height: _trackHeight - 8.0,
    child: _ClipWidget(
    clip: clip,
   isSelected: isSelected,
        waveformData: widget.clipWaveforms[clip.clipId],
        trackHeight: _trackHeight,
        trackCount: widget.tracks.length,
   originalDuration: originalDuration,
        timeToX: _timeToX,
        xToTime: _xToTime,
   isAudioOnly: clip.isAudioOnly,
  snapEnabled: editorState.snapEnabled,
allClips: widget.clips,
        onTap: () {
try {
     widget.onClipSelect(clip.clipId);
  } catch (e) {
     debugPrint('Error selecting clip: $e');
   }
      },
        onMove: (newTimeMs, newTrackIndex) {
    try {
     // Validate new position
       if (newTimeMs < 0 || newTimeMs > 60000 * 10) {
  debugPrint('Invalid time position: $newTimeMs');
        return;
  }
    
      // Validate track index is within bounds
      final sortedTracks = [...widget.tracks]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  if (newTrackIndex < 0 || newTrackIndex >= sortedTracks.length) {
   debugPrint('Invalid track index: $newTrackIndex');
           return;
 }
         
      // Get actual track ID from visual track index (using sorted list)
      final track = sortedTracks[newTrackIndex];
 
   // Move clip to new position
     widget.onClipMove(clip.clipId, newTimeMs);
         
 // Change track if different (using track ID, not visual index)
    if (track.trackId != clip.trackIndex) {
widget.onClipChangeTrack(clip.clipId, track.trackId);
      }
     } catch (e) {
 debugPrint('Error moving clip ${clip.clipId}: $e');
     }
        },
        onMoveComplete: () {
      // NEW: Callback when move drag completes
   final editorNotifier = ref.read(editorProvider.notifier);
      editorNotifier.commitClipMove();
        },
        onTrimComplete: (trimStartMs, trimEndMs) {
        try {
 // Call the new setClipTrim method with absolute values
  final editorNotifier = ref.read(editorProvider.notifier);
        editorNotifier.setClipTrim(clip.clipId, trimStartMs, trimEndMs);
      } catch (e) {
        debugPrint('Error setting trim: $e');
 }
  },
      ),  // Close _ClipWidget
    );  // Close Positioned
  }

  // NEW: Build text layer widget on its track
  Widget _buildTextLayerOnTrack(TextLayerData layer) {
    final x = _timeToX(layer.startTimeMs);
    final width = _timeToX(layer.durationMs);
    
    // IMPORTANT: Sort tracks the same way as _buildTracks() does
    final sortedTracks = [...widget.tracks]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    
    // Find the track that contains this text layer IN THE SORTED LIST
    final trackIndex = sortedTracks.indexWhere((t) => t.trackId == layer.trackIndex);
if (trackIndex == -1) return const SizedBox.shrink();  // Track doesn't exist
    
    final track = sortedTracks[trackIndex];
 
 // Only render on TEXT or OVERLAY tracks
  if (track.trackType != TrackType.text && track.trackType != TrackType.overlay) {
      return const SizedBox.shrink();
    }
    
    // Don't render if track is invisible
    if (!track.isVisible) return const SizedBox.shrink();
  
    final y = trackIndex * _trackHeight.toDouble();
    final isSelected = layer.layerId == widget.selectedTextLayerId;

    return Positioned(
      left: x,
  top: y + 10,  // Small padding from top of track
   width: width.clamp(80, double.infinity),
 height: _trackHeight - 20.0,// Leave padding top and bottom
      child: _TextLayerWidget(
        layer: layer,
        isSelected: isSelected,
        trackHeight: _trackHeight,
  trackCount: widget.tracks.length,
 tracks: sortedTracks,  // Pass sorted tracks to text layer widget
    timeToX: _timeToX,
     xToTime: _xToTime,
  onTap: () => widget.onTextLayerSelect(layer.layerId),
        onMove: (newTimeMs, newTrackIndex) {
     // Move text layer to new time position
     widget.onTextLayerMove(layer.layerId, newTimeMs);
     
        // Change track if different
          if (newTrackIndex != trackIndex) {
  final newTrack = sortedTracks[newTrackIndex];  // Use sorted list
   
   // Only allow moving to TEXT or OVERLAY tracks
      if (newTrack.trackType == TrackType.text || newTrack.trackType == TrackType.overlay) {
         final editorNotifier = ref.read(editorProvider.notifier);
   final updatedLayer = layer.copyWith(trackIndex: newTrack.trackId);
       editorNotifier.updateTextLayer(layer.layerId, updatedLayer);
    }
        }
        },
   ),
 );
  }

  Widget _buildPlayhead() {
    final x = _timeToX(widget.currentTimeMs);

    // Only access scroll offset if controller is attached
 final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;

 return Positioned(
  left: x - scrollOffset,
      top: 0,
      bottom: 0,
      child: Container(
    width: 2,
    decoration: BoxDecoration(
color: AppColors.accentBlue,
       boxShadow: [
     BoxShadow(
  color: AppColors.accentBlueGlow,
   blurRadius: 8,
       spreadRadius: 1,
   ),
     ],
     ),
      child: Align(
   alignment: Alignment.topCenter,
          child: Container(
       width: 12,
   height: 12,
decoration: BoxDecoration(
     color: AppColors.accentBlue,
   shape: BoxShape.circle,
       boxShadow: [
     BoxShadow(
       color: AppColors.accentBlueGlow,
       blurRadius: 8,
       spreadRadius: 2,
       ),
        ],
       ),
    ),
   ),
 ),
    );
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

class TimeRulerPainter extends CustomPainter {
  final double zoom;

  TimeRulerPainter({required this.zoom});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.dividerColor
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw major ticks every second
    for (int i = 0; i <= 600; i++) {
      final x = (i * 100 * zoom);
if (x > size.width) break;

 // Draw tick
    canvas.drawLine(
 Offset(x, size.height - (i % 5 == 0 ? 12 : 8)),
      Offset(x, size.height),
    paint,
      );

  // Draw time label every 5 seconds
      if (i % 5 == 0) {
        textPainter.text = TextSpan(
  text: '${i}s',
          style: TextStyle(
       color: AppColors.textTertiary,
fontSize: 10,
    fontWeight: FontWeight.w500,
 ),
   );
 textPainter.layout();
        textPainter.paint(canvas, Offset(x + 2, 4));
   }
    }
  }

  @override
  bool shouldRepaint(TimeRulerPainter oldDelegate) => oldDelegate.zoom != zoom;
}

// Waveform painter for audio visualization
class _WaveformPainter extends CustomPainter {
  final int clipId;
  final Color color;
  final List<double>? waveformData;

  _WaveformPainter({
    required this.clipId,
    required this.color,
    this.waveformData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData == null || waveformData!.isEmpty) {
      // No waveform data available
      return;
    }

    final sampleCount = waveformData!.length;
    final centerY = size.height / 2;
    final sampleWidth = size.width / sampleCount;
  
    // Create gradient for better visual effect
    final gradient = LinearGradient(
    begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.8),
     color.withOpacity(0.4),
        color.withOpacity(0.4),
     color.withOpacity(0.8),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
  ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    // Draw filled waveform path (top half)
final topPath = Path();
    topPath.moveTo(0, centerY);

    for (int i = 0; i < sampleCount; i++) {
      final x = i * sampleWidth;
final amplitude = waveformData![i];
      final height = amplitude * size.height * 0.45; // Use 45% of height for peaks
      final y = centerY - height;
      
      if (i == 0) {
        topPath.lineTo(x, y);
      } else {
      // Smooth curve between points
        final prevX = (i - 1) * sampleWidth;
        final prevAmplitude = waveformData![i - 1];
        final prevHeight = prevAmplitude * size.height * 0.45;
  final prevY = centerY - prevHeight;
   
  final controlX = (prevX + x) / 2;
        topPath.quadraticBezierTo(controlX, prevY, x, y);
   }
    }

    // Complete the top path
    topPath.lineTo(size.width, centerY);
    topPath.lineTo(0, centerY);
    topPath.close();
    canvas.drawPath(topPath, paint);

    // Draw filled waveform path (bottom half - mirror)
    final bottomPath = Path();
    bottomPath.moveTo(0, centerY);

    for (int i = 0; i < sampleCount; i++) {
      final x = i * sampleWidth;
      final amplitude = waveformData![i];
      final height = amplitude * size.height * 0.45;
      final y = centerY + height;
      
      if (i == 0) {
        bottomPath.lineTo(x, y);
   } else {
     final prevX = (i - 1) * sampleWidth;
        final prevAmplitude = waveformData![i - 1];
        final prevHeight = prevAmplitude * size.height * 0.45;
        final prevY = centerY + prevHeight;
     
        final controlX = (prevX + x) / 2;
  bottomPath.quadraticBezierTo(controlX, prevY, x, y);
      }
    }

    bottomPath.lineTo(size.width, centerY);
    bottomPath.lineTo(0, centerY);
    bottomPath.close();
    canvas.drawPath(bottomPath, paint);

    // Draw center line for clarity
    final centerLinePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerLinePaint,
    );

    // Draw outline for definition
    final outlinePaint = Paint()
   ..color = color.withOpacity(0.6)
    ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Top outline
 final topOutline = Path();
    topOutline.moveTo(0, centerY);
  for (int i = 0; i < sampleCount; i++) {
      final x = i * sampleWidth;
    final amplitude = waveformData![i];
      final height = amplitude * size.height * 0.45;
      final y = centerY - height;
      
      if (i == 0) {
        topOutline.lineTo(x, y);
      } else {
      final prevX = (i - 1) * sampleWidth;
        final prevAmplitude = waveformData![i - 1];
    final prevHeight = prevAmplitude * size.height * 0.45;
     final prevY = centerY - prevHeight;
   final controlX = (prevX + x) / 2;
 topOutline.quadraticBezierTo(controlX, prevY, x, y);
      }
    }
    canvas.drawPath(topOutline, outlinePaint);

    // Bottom outline
    final bottomOutline = Path();
    bottomOutline.moveTo(0, centerY);
    for (int i = 0; i < sampleCount; i++) {
      final x = i * sampleWidth;
   final amplitude = waveformData![i];
      final height = amplitude * size.height * 0.45;
      final y = centerY + height;
      
  if (i == 0) {
        bottomOutline.lineTo(x, y);
      } else {
 final prevX = (i - 1) * sampleWidth;
        final prevAmplitude = waveformData![i - 1];
        final prevHeight = prevAmplitude * size.height * 0.45;
        final prevY = centerY + prevHeight;
  final controlX = (prevX + x) / 2;
        bottomOutline.quadraticBezierTo(controlX, prevY, x, y);
    }
    }
    canvas.drawPath(bottomOutline, outlinePaint);
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
  return oldDelegate.clipId != clipId || 
    oldDelegate.color != color ||
      oldDelegate.waveformData != waveformData;
  }
}

// Professional clip widget with drag, resize, and track change support
class _ClipWidget extends StatefulWidget {
  final ClipData clip;
  final bool isSelected;
  final List<double>? waveformData;
  final int trackHeight;
  final int trackCount;
  final int originalDuration;
  final double Function(int) timeToX;
  final int Function(double) xToTime;
  final bool isAudioOnly;  // NEW: Audio-only flag
  final bool snapEnabled;  // NEW: Add snap enabled flag
  final List<ClipData> allClips;  // NEW: All clips for snap points
  final VoidCallback onTap;
  final Function(int newTimeMs, int newTrackIndex) onMove;
  final VoidCallback onMoveComplete; // NEW: Called when move drag completes
  final Function(int trimStartMs, int trimEndMs) onTrimComplete;

  const _ClipWidget({
    required this.clip,
    required this.isSelected,
    this.waveformData,
    required this.trackHeight,
    required this.trackCount,
    required this.originalDuration,
    required this.timeToX,
    required this.xToTime,
    this.isAudioOnly = false,  // NEW: Default to false
    this.snapEnabled = true,  // NEW: Default to true
    this.allClips = const [],  // NEW: Default empty
    required this.onTap,
    required this.onMove,
    required this.onMoveComplete, // NEW
    required this.onTrimComplete,
  });

  @override
  State<_ClipWidget> createState() => _ClipWidgetState();
}

class _ClipWidgetState extends State<_ClipWidget> {
  DragMode _dragMode = DragMode.none;
  Offset _dragStartGlobal = Offset.zero;
  double _dragStartX = 0;
  double _dragStartY = 0;
  int _dragStartTime = 0;
  int _dragStartTrack = 0;
  
  // Store initial trim values when drag starts
  int _initialTrimStart = 0;
  int _initialTrimEnd = 0;
  
// Store calculated trim values during drag (not applied until end)
  int _pendingTrimStart = 0;
  int _pendingTrimEnd = 0;
  
  final double _resizeHandleWidth = 8.0;
  static const int _snapThresholdMs = 200;
  bool _isSnapped = false;  // NEW: Track if currently snapped

  // NEW: Track move operation state
  int _finalMoveTime = 0;
  int _finalMoveTrack = 0;

  // NEW: Calculate snap points from other clips
  int _findSnapPoint(int timeMs, {bool isEndPoint = false}) {
    if (!widget.snapEnabled) {
      setState(() => _isSnapped = false);
      return timeMs;
    }

    int closestSnap = timeMs;
  int minDistance = _snapThresholdMs;

    // Collect all snap points from other clips
    final snapPoints = <int>[];
    
    for (final otherClip in widget.allClips) {
      if (otherClip.clipId == widget.clip.clipId) continue;  // Skip self
      
      // Add start and end points of other clips as snap targets
      snapPoints.add(otherClip.startTimeMs);
      snapPoints.add(otherClip.endTimeMs);
    }
    
    // Also snap to timeline start (0ms)
    snapPoints.add(0);

  // Find closest snap point
    for (final snapPoint in snapPoints) {
      final distance = (timeMs - snapPoint).abs();
      if (distance < minDistance) {
        minDistance = distance;
    closestSnap = snapPoint;
    }
    }

    // Update snapped state
    final snapped = closestSnap != timeMs;
    if (snapped != _isSnapped) {
      setState(() => _isSnapped = snapped);
    }

    return closestSnap;
  }

  // NEW: Find snap point considering both start and end of the clip
  int _findSnapPointForMove(int proposedStartMs) {
    if (!widget.snapEnabled) {
      setState(() => _isSnapped = false);
      return proposedStartMs;
    }

    final clipDuration = widget.clip.durationMs;
    final proposedEndMs = proposedStartMs + clipDuration;

    int closestSnapStart = proposedStartMs;
    int closestSnapEnd = proposedStartMs;
    int minDistanceStart = _snapThresholdMs;
  int minDistanceEnd = _snapThresholdMs;

    // Collect all snap points from other clips
    final snapPoints = <int>[];
    
    for (final otherClip in widget.allClips) {
      if (otherClip.clipId == widget.clip.clipId) continue;  // Skip self
      
      // Add start and end points of other clips as snap targets
      snapPoints.add(otherClip.startTimeMs);
      snapPoints.add(otherClip.endTimeMs);
    }
    
    // Also snap to timeline start (0ms)
    snapPoints.add(0);

    // Check if clip's START should snap to any point
    for (final snapPoint in snapPoints) {
      final distance = (proposedStartMs - snapPoint).abs();
    if (distance < minDistanceStart) {
        minDistanceStart = distance;
        closestSnapStart = snapPoint;
      }
    }

    // Check if clip's END should snap to any point
    for (final snapPoint in snapPoints) {
      final distance = (proposedEndMs - snapPoint).abs();
      if (distance < minDistanceEnd) {
        minDistanceEnd = distance;
     closestSnapEnd = snapPoint - clipDuration;  // Adjust to get start position
      }
    }

    // Choose the closer snap (start or end)
    int finalPosition;
    bool snapped;
    
    if (minDistanceStart <= minDistanceEnd) {
      // Snap using start point
      finalPosition = closestSnapStart;
      snapped = closestSnapStart != proposedStartMs;
} else {
      // Snap using end point
      finalPosition = closestSnapEnd;
      snapped = closestSnapEnd != proposedStartMs;
    }

    // Update snapped state
    if (snapped != _isSnapped) {
   setState(() => _isSnapped = snapped);
  }

    return finalPosition;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
 cursor: _getCursor(),
          child: GestureDetector(
            onTapDown: (details) {
      _handleTapDown(details, constraints.maxWidth);
            },
    onPanStart: (details) {
          _handlePanStart(details, constraints.maxWidth);
      },
       onPanUpdate: (details) {
              _handlePanUpdate(details);
  },
            onPanEnd: (_) {
        // Apply final changes when drag ends
 if (_dragMode == DragMode.move) {
      // Only push state if position actually changed
     if (_finalMoveTime != _dragStartTime || _finalMoveTrack != _dragStartTrack) {
     debugPrint('END DRAG: Move from ${_dragStartTime}ms to ${_finalMoveTime}ms');
   // This final call ensures visual state is correct
       widget.onMove(_finalMoveTime, _finalMoveTrack);
  // NEW: Call completion callback to push undo state
     widget.onMoveComplete();
    }
      } else if (_dragMode == DragMode.resizeStart || _dragMode == DragMode.resizeEnd) {
     // Check if trim values actually changed
    if (_pendingTrimStart != widget.clip.trimStartMs || 
    _pendingTrimEnd != widget.clip.trimEndMs) {
 debugPrint('END DRAG: Applying trim - Start: ${_pendingTrimStart}ms, End: ${_pendingTrimEnd}ms (Changed from ${widget.clip.trimStartMs}ms to ${widget.clip.trimEndMs}ms)');
     widget.onTrimComplete(_pendingTrimStart, _pendingTrimEnd);
   } else {
   debugPrint('END DRAG: No trim change');
 }
}
   
   setState(() {
  _dragMode = DragMode.none;
   });
      },
            child: _buildClipContent(constraints.maxWidth),
        ),
        );
      },
    );
  }

  void _handleTapDown(TapDownDetails details, double width) {
    final localX = details.localPosition.dx;
    
    if (localX < _resizeHandleWidth) {
      // Clicking on left edge - will resize start
    } else if (localX > width - _resizeHandleWidth) {
      // Clicking on right edge - will resize end
    } else {
      // Clicking on body - select clip
    widget.onTap();
    }
  }

  void _handlePanStart(DragStartDetails details, double width) {
    final localX = details.localPosition.dx;
    _dragStartGlobal = details.globalPosition;
    
    // Store initial values
    _dragStartTime = widget.clip.startTimeMs;
    _dragStartTrack = widget.clip.trackIndex;
    _dragStartX = widget.timeToX(widget.clip.startTimeMs);
    _dragStartY = widget.clip.trackIndex * widget.trackHeight.toDouble();
    
 // Store initial trim values
    _initialTrimStart = widget.clip.trimStartMs;
  _initialTrimEnd = widget.clip.trimEndMs;
    _pendingTrimStart = _initialTrimStart;
    _pendingTrimEnd = _initialTrimEnd;
 
    // Initialize final move position
    _finalMoveTime = _dragStartTime;
    _finalMoveTrack = _dragStartTrack;

    // Determine drag mode based on where user clicked
    if (localX < _resizeHandleWidth) {
      setState(() => _dragMode = DragMode.resizeStart);
    debugPrint('START DRAG: Resize Start - Initial trim: ${_initialTrimStart}ms to ${_initialTrimEnd}ms (duration: ${widget.originalDuration}ms)');
    } else if (localX > width - _resizeHandleWidth) {
      setState(() => _dragMode = DragMode.resizeEnd);
    debugPrint('START DRAG: Resize End - Initial trim: ${_initialTrimStart}ms to ${_initialTrimEnd}ms (duration: ${widget.originalDuration}ms)');
    } else {
   setState(() => _dragMode = DragMode.move);
    }
  }

  void _handlePanUpdate(details) {
    if (_dragMode == DragMode.none) return;

  try {
      if (_dragMode == DragMode.move) {
        // Calculate new position from global movement
     final totalDelta = details.globalPosition - _dragStartGlobal;
        
   // Calculate new time from horizontal movement
 final newX = _dragStartX + totalDelta.dx;
int newTimeMs = widget.xToTime(newX).clamp(0, 60000 * 10);
    
      // NEW: Apply snapping for both clip start AND end positions
        if (widget.snapEnabled) {
      newTimeMs = _findSnapPointForMove(newTimeMs);
        }
        
 // Calculate new track from vertical movement
   final newY = _dragStartY + totalDelta.dy;
  final newTrack = ((newY + widget.trackHeight / 2) / widget.trackHeight)
        .floor()
 .clamp(0, widget.trackCount - 1);
        
        // Store final position, but DON'T call onMove yet (it triggers pushState)
_finalMoveTime = newTimeMs;
  _finalMoveTrack = newTrack;
      
        // Still call onMove for visual update (provider will NOT call pushState during drag)
     widget.onMove(newTimeMs, newTrack);
   
  } else if (_dragMode == DragMode.resizeStart) {
        // RESIZE LEFT EDGE - Controls trim_start
        // Drag RIGHT (+dx) = SKIP more from start = INCREASE trim_start = SHORTER clip
        // Drag LEFT (-dx) = SKIP less from start = DECREASE trim_start = LONGER clip
        
        final totalDelta = details.globalPosition - _dragStartGlobal;
        final deltaX = totalDelta.dx;
    
        // Convert pixel movement to time
        final deltaTimeMs = widget.xToTime(deltaX.abs()) - widget.xToTime(0);
        final signedDeltaMs = deltaX < 0 ? -deltaTimeMs : deltaTimeMs;
        
  // Calculate new trim start from initial value
        _pendingTrimStart = (_initialTrimStart + signedDeltaMs)
            .clamp(0, _initialTrimEnd - 100);
 
      } else if (_dragMode == DragMode.resizeEnd) {
        // RESIZE RIGHT EDGE - Controls trim_end
   // Drag RIGHT (+dx) = INCLUDE more = INCREASE trim_end = LONGER clip
        // Drag LEFT (-dx) = INCLUDE less = DECREASE trim_end = SHORTER clip
        
        final totalDelta = details.globalPosition - _dragStartGlobal;
        final deltaX = totalDelta.dx;
        
        // Convert pixel movement to time
 final deltaTimeMs = widget.xToTime(deltaX.abs()) - widget.xToTime(0);
      final signedDeltaMs = deltaX < 0 ? -deltaTimeMs : deltaTimeMs;
        
        // Calculate new trim end from initial value
        // Can expand back to original video duration
 _pendingTrimEnd = (_initialTrimEnd + signedDeltaMs)
         .clamp(_initialTrimStart + 100, widget.originalDuration);
      }
    } catch (e) {
      debugPrint('Error during drag update: $e');
      setState(() => _dragMode = DragMode.none);
    }
  }

  Widget _buildClipContent(double width) {
    // Define colors based on clip type - Modern blue/green palette
    final Color baseColor = widget.isAudioOnly
        ? const Color(0xFF00C853)  // Green for audio (matching track accent)
 : const Color(0xFF2196F3);  // Blue for video (matching track accent)
    
    final Color selectedColor = widget.isAudioOnly
   ? const Color(0xFF00E676)  // Brighter green when selected
   : const Color(0xFF42A5F5);  // Brighter blue when selected
    
 return Container(
     decoration: BoxDecoration(
     color: widget.isSelected ? selectedColor : baseColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusS),
        border: Border.all(
   color: _isSnapped 
        ? AppColors.accentBlue  // Blue border when snapped
            : (widget.isSelected ? AppColors.textPrimary : Colors.transparent),
  width: _isSnapped ? 2 : (widget.isSelected ? 2 : 0),
   ),
  boxShadow: [
     BoxShadow(
     color: _isSnapped 
   ? AppColors.accentBlueGlow  // Blue glow when snapped
        : AppColors.blackOverlay50.withOpacity(_dragMode != DragMode.none ? 0.6 : 0.3),
       blurRadius: _isSnapped ? 8 : (_dragMode != DragMode.none ? 6 : 3),
            offset: Offset(0, _dragMode != DragMode.none ? 3 : 1),
 ),
        ],
      ),
   child: ClipRRect(
    borderRadius: BorderRadius.circular(AppSpacing.radiusS),
        child: Stack(
          children: [
// Audio waveform background (only for audio-only clips)
      if (widget.isAudioOnly && widget.waveformData != null)
         Positioned.fill(
  child: CustomPaint(
     painter: _WaveformPainter(
  clipId: widget.clip.clipId,
          color: AppColors.textPrimary.withOpacity(0.3),
         waveformData: widget.waveformData,
  ),
     ),
      ),

   // Left resize handle
Positioned(
       left: 0,
   top: 0,
     bottom: 0,
    width: _resizeHandleWidth,
       child: Container(
    decoration: BoxDecoration(
    color: _dragMode == DragMode.resizeStart 
      ? AppColors.accentBlueDim
         : Colors.transparent,
   border: Border(
     left: BorderSide(
   color: widget.isSelected 
       ? AppColors.textPrimary.withOpacity(0.8)
      : AppColors.textPrimary.withOpacity(0.2),
       width: 2,
        ),
  ),
    ),
   child: Center(
       child: Container(
      width: 2,
     height: 16,
     decoration: BoxDecoration(
        color: AppColors.textPrimary.withOpacity(0.5),
     borderRadius: BorderRadius.circular(1),
    ),
      ),
      ),
  ),
   ),

     // Right resize handle
  Positioned(
        right: 0,
   top: 0,
   bottom: 0,
   width: _resizeHandleWidth,
        child: Container(
  decoration: BoxDecoration(
       color: _dragMode == DragMode.resizeEnd 
 ? AppColors.accentBlueDim
: Colors.transparent,
        border: Border(
    right: BorderSide(
 color: widget.isSelected 
    ? AppColors.textPrimary.withOpacity(0.8)
   : AppColors.textPrimary.withOpacity(0.2),
 width: 2,
    ),
      ),
    ),
   child: Center(
   child: Container(
         width: 2,
    height: 16,
       decoration: BoxDecoration(
     color: AppColors.textPrimary.withOpacity(0.5),
     borderRadius: BorderRadius.circular(1),
   ),
      ),
      ),
 ),
     ),

   // Clip info
   Positioned(
    left: _resizeHandleWidth + 4,
       top: 4,
        right: _resizeHandleWidth + 4,
     child: Column(
   crossAxisAlignment: CrossAxisAlignment.start,
   mainAxisSize: MainAxisSize.min,
    children: [
  Row(
  children: [
       Expanded(
    child: Text(
  widget.isAudioOnly 
 ? 'Audio ${widget.clip.clipId}'
        : 'Clip ${widget.clip.clipId}',
    style: AppTypography.labelSmall.copyWith(
  fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  ),
   overflow: TextOverflow.ellipsis,
      maxLines: 1,
   ),
         ),
      // NEW: Scale indicator
          if (widget.clip.scaleX != 1.0 || widget.clip.scaleY != 1.0)
            Container(
  margin: const EdgeInsets.only(left: 4),
         padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
              ),
  child: Text(
   '${(widget.clip.scaleX * 100).toStringAsFixed(0)}%',
     style: AppTypography.labelSmall.copyWith(
 fontSize: 8,
     color: AppColors.accentBlue,
    fontWeight: FontWeight.w600,
     ),
     ),
     ),
          ],
     ),
   if (widget.clip.speed != 1.0)
   Text(
    '${widget.clip.speed}x',
 style: AppTypography.labelSmall.copyWith(
  fontSize: 9,
       color: AppColors.accentBlue,
        ),
     ),
     ],
   ),
       ),

       // Dragging overlay
  if (_dragMode != DragMode.none)
    Positioned.fill(
    child: Container(
   decoration: BoxDecoration(
       color: AppColors.hoverOverlay,
     borderRadius: BorderRadius.circular(AppSpacing.radiusS),
       border: Border.all(
    color: AppColors.textPrimary.withOpacity(0.3),
   width: 1,
      ),
    ),
          ),
    ),
 ],
   ),
      ),
 );
  }

  MouseCursor _getCursor() {
    if (_dragMode == DragMode.resizeStart || _dragMode == DragMode.resizeEnd) {
      return SystemMouseCursors.resizeLeftRight;
    } else if (_dragMode == DragMode.move) {
      return SystemMouseCursors.grabbing;
    } else {
  return SystemMouseCursors.grab;
    }
  }
}

enum DragMode {
  none,
  move,
  resizeStart,
  resizeEnd,
}

// NEW: Text layer widget with track change support
class _TextLayerWidget extends StatefulWidget {
  final TextLayerData layer;
  final bool isSelected;
  final int trackHeight;
  final int trackCount;
  final List<TrackData> tracks;
  final double Function(int) timeToX;
  final int Function(double) xToTime;
  final VoidCallback onTap;
  final Function(int newTimeMs, int newTrackIndex) onMove;

  const _TextLayerWidget({
    required this.layer,
    required this.isSelected,
    required this.trackHeight,
    required this.trackCount,
    required this.tracks,
    required this.timeToX,
    required this.xToTime,
    required this.onTap,
    required this.onMove,
  });

  @override
  State<_TextLayerWidget> createState() => _TextLayerWidgetState();
}

class _TextLayerWidgetState extends State<_TextLayerWidget> {
  bool _isDragging = false;
  Offset _dragStartGlobal = Offset.zero;
  double _dragStartX = 0;
  double _dragStartY = 0;

  void _handlePanStart(DragStartDetails details) {
    _dragStartGlobal = details.globalPosition;
    _dragStartX = widget.timeToX(widget.layer.startTimeMs);
    
    // Find current track index for Y position
    final currentTrackIndex = widget.tracks.indexWhere((t) => t.trackId == widget.layer.trackIndex);
    _dragStartY = currentTrackIndex * widget.trackHeight.toDouble();
    
    setState(() => _isDragging = true);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
  if (!_isDragging) return;

    final totalDelta = details.globalPosition - _dragStartGlobal;
    
// Calculate new time from horizontal movement
    final newX = _dragStartX + totalDelta.dx;
    int newTimeMs = widget.xToTime(newX).clamp(0, 60000 * 10);
    
    // Calculate new track from vertical movement
  final newY = _dragStartY + totalDelta.dy;
    int newTrackIndex = ((newY + widget.trackHeight / 2) / widget.trackHeight)
        .floor()
        .clamp(0, widget.trackCount - 1);
  
    widget.onMove(newTimeMs, newTrackIndex);
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
  }

  @override
  Widget build(BuildContext context) {
return GestureDetector(
      onTap: widget.onTap,
    onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: MouseRegion(
        cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
child: Container(
      decoration: BoxDecoration(
          color: widget.isSelected ? Colors.purple[400] : Colors.deepPurple,
            borderRadius: BorderRadius.circular(4),
         border: Border.all(
       color: widget.isSelected ? Colors.white : Colors.transparent,
 width: 2,
       ),
      boxShadow: [
   BoxShadow(
     color: Colors.black45,
    blurRadius: _isDragging ? 8 : 4,
            offset: Offset(0, _isDragging ? 4 : 2),
              ),
        ],
     ),
          child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  child: Row(
         children: [
      const Icon(Icons.text_fields, size: 16, color: Colors.white),
        const SizedBox(width: 4),
        Expanded(
       child: Text(
       widget.layer.text.isEmpty ? 'Text Layer ${widget.layer.layerId}' : widget.layer.text,
      style: const TextStyle(
    fontSize: 12,
              color: Colors.white,
   fontWeight: FontWeight.w500,
     ),
        overflow: TextOverflow.ellipsis,
     ),
          ),
       ],
    ),
   ),
      ),
    ),
    );
  }
}

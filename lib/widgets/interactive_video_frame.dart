import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import '../providers/editor_provider.dart';
import '../native/video_engine_wrapper.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

enum ResizeHandle {
  none,
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

class InteractiveVideoFrame extends ConsumerStatefulWidget {
  final ui.Image? frame;
  final ClipData? selectedClip;
  final Size containerSize;

  const InteractiveVideoFrame({
    super.key,
    required this.frame,
    required this.selectedClip,
    required this.containerSize,
  });

  @override
  ConsumerState<InteractiveVideoFrame> createState() => _InteractiveVideoFrameState();
}

class _InteractiveVideoFrameState extends ConsumerState<InteractiveVideoFrame> {
  ResizeHandle _activeHandle = ResizeHandle.none;
  ResizeHandle _hoveredHandle = ResizeHandle.none;
  Offset? _dragStart;
  double _initialScaleX = 1.0;
  double _initialScaleY = 1.0;

  static const double _handleSize = 16.0;
static const double _handleHitArea = 24.0;

  @override
  Widget build(BuildContext context) {
 if (widget.frame == null || widget.selectedClip == null) {
      return const SizedBox.shrink();
    }

    final clip = widget.selectedClip!;
    final frame = widget.frame!;

    return MouseRegion(
      cursor: _getCursor(),
   onHover: (event) {
        if (_activeHandle == ResizeHandle.none) {
          setState(() {
            _hoveredHandle = _detectHandle(event.localPosition);
          });
        }
      },
      onExit: (_) {
 setState(() {
   _hoveredHandle = ResizeHandle.none;
        });
      },
      child: GestureDetector(
  onPanStart: (details) {
  _dragStart = details.localPosition;
          _activeHandle = _detectHandle(details.localPosition);
          _initialScaleX = clip.scaleX;
          _initialScaleY = clip.scaleY;
        },
  onPanUpdate: (details) {
     if (_activeHandle != ResizeHandle.none && _dragStart != null) {
     _handleResize(details.localPosition);
          }
        },
onPanEnd: (_) {
          setState(() {
       _activeHandle = ResizeHandle.none;
_dragStart = null;
     });
        },
        child: CustomPaint(
     painter: _InteractiveFramePainter(
    frame: frame,
            scaleX: clip.scaleX,
            scaleY: clip.scaleY,
            showHandles: true,
     hoveredHandle: _hoveredHandle,
      activeHandle: _activeHandle,
          ),
          size: widget.containerSize,
   ),
      ),
    );
  }

  ResizeHandle _detectHandle(Offset position) {
    final rect = _getVideoRect();
    if (rect == null) return ResizeHandle.none;

    // Check corners first (higher priority)
    if (_isNear(position, rect.topLeft, _handleHitArea)) return ResizeHandle.topLeft;
    if (_isNear(position, rect.topRight, _handleHitArea)) return ResizeHandle.topRight;
    if (_isNear(position, rect.bottomLeft, _handleHitArea)) return ResizeHandle.bottomLeft;
    if (_isNear(position, rect.bottomRight, _handleHitArea)) return ResizeHandle.bottomRight;

    // Check edges
    if (_isNearHorizontalEdge(position, rect.top, rect.left, rect.right, _handleHitArea)) {
      return ResizeHandle.top;
    }
    if (_isNearHorizontalEdge(position, rect.bottom, rect.left, rect.right, _handleHitArea)) {
      return ResizeHandle.bottom;
  }
    if (_isNearVerticalEdge(position, rect.left, rect.top, rect.bottom, _handleHitArea)) {
  return ResizeHandle.left;
    }
    if (_isNearVerticalEdge(position, rect.right, rect.top, rect.bottom, _handleHitArea)) {
      return ResizeHandle.right;
    }

 return ResizeHandle.none;
  }

  Rect? _getVideoRect() {
    if (widget.frame == null || widget.selectedClip == null) return null;

    final clip = widget.selectedClip!;
    final frame = widget.frame!;
    final containerSize = widget.containerSize;

  // Calculate actual video dimensions considering letterboxing
    // This matches _FramePainter logic
    final imageAspect = frame.width / frame.height;
    final containerAspect = containerSize.width / containerSize.height;

    double videoWidth, videoHeight, offsetX = 0, offsetY = 0;

    if (imageAspect > containerAspect) {
      // Image is wider than container - fit to width
    videoWidth = containerSize.width;
      videoHeight = containerSize.width / imageAspect;
      offsetY = (containerSize.height - videoHeight) / 2;
    } else {
      // Image is taller than container - fit to height
      videoHeight = containerSize.height;
      videoWidth = containerSize.height * imageAspect;
      offsetX = (containerSize.width - videoWidth) / 2;
    }

    // Now apply clip scaling to the letterboxed video
    final scaledWidth = videoWidth * clip.scaleX;
    final scaledHeight = videoHeight * clip.scaleY;

    // Center the scaled video within the letterboxed area
    final left = offsetX + (videoWidth - scaledWidth) / 2;
    final top = offsetY + (videoHeight - scaledHeight) / 2;

    return Rect.fromLTWH(left, top, scaledWidth, scaledHeight);
  }

  bool _isNear(Offset point, Offset target, double threshold) {
    return (point - target).distance < threshold;
  }

  bool _isNearHorizontalEdge(Offset point, double edgeY, double startX, double endX, double threshold) {
    return (point.dy - edgeY).abs() < threshold && point.dx >= startX - threshold && point.dx <= endX + threshold;
  }

  bool _isNearVerticalEdge(Offset point, double edgeX, double startY, double endY, double threshold) {
    return (point.dx - edgeX).abs() < threshold && point.dy >= startY - threshold && point.dy <= endY + threshold;
  }

  void _handleResize(Offset currentPosition) {
    if (_dragStart == null || widget.selectedClip == null || widget.frame == null) return;

    final clip = widget.selectedClip!;
    final frame = widget.frame!;
    final delta = currentPosition - _dragStart!;

    // Get the base video size (letterboxed, before scaling)
    final imageAspect = frame.width / frame.height;
    final containerAspect = widget.containerSize.width / widget.containerSize.height;

 double baseVideoWidth, baseVideoHeight;
    if (imageAspect > containerAspect) {
      baseVideoWidth = widget.containerSize.width;
      baseVideoHeight = widget.containerSize.width / imageAspect;
    } else {
      baseVideoHeight = widget.containerSize.height;
      baseVideoWidth = widget.containerSize.height * imageAspect;
    }

    double newScaleX = _initialScaleX;
    double newScaleY = _initialScaleY;

    // Calculate scale change based on handle using base video dimensions
    switch (_activeHandle) {
      case ResizeHandle.topLeft:
        newScaleX = _initialScaleX - (delta.dx / baseVideoWidth) * 2;
        newScaleY = _initialScaleY - (delta.dy / baseVideoHeight) * 2;
        break;
      case ResizeHandle.top:
        newScaleY = _initialScaleY - (delta.dy / baseVideoHeight) * 2;
break;
      case ResizeHandle.topRight:
  newScaleX = _initialScaleX + (delta.dx / baseVideoWidth) * 2;
   newScaleY = _initialScaleY - (delta.dy / baseVideoHeight) * 2;
        break;
      case ResizeHandle.right:
        newScaleX = _initialScaleX + (delta.dx / baseVideoWidth) * 2;
        break;
   case ResizeHandle.bottomRight:
        newScaleX = _initialScaleX + (delta.dx / baseVideoWidth) * 2;
        newScaleY = _initialScaleY + (delta.dy / baseVideoHeight) * 2;
        break;
   case ResizeHandle.bottom:
        newScaleY = _initialScaleY + (delta.dy / baseVideoHeight) * 2;
        break;
    case ResizeHandle.bottomLeft:
        newScaleX = _initialScaleX - (delta.dx / baseVideoWidth) * 2;
        newScaleY = _initialScaleY + (delta.dy / baseVideoHeight) * 2;
        break;
      case ResizeHandle.left:
   newScaleX = _initialScaleX - (delta.dx / baseVideoWidth) * 2;
        break;
      case ResizeHandle.none:
        return;
    }

    // Apply aspect ratio lock
    if (clip.lockAspectRatio) {
      final avgScale = (newScaleX + newScaleY) / 2;
      newScaleX = avgScale;
      newScaleY = avgScale;
    }

    // Clamp values
    newScaleX = newScaleX.clamp(0.01, 5.0);
    newScaleY = newScaleY.clamp(0.01, 5.0);

    // Update via provider
    ref.read(editorProvider.notifier).setClipScale(clip.clipId, newScaleX, newScaleY);
  }

  MouseCursor _getCursor() {
    final handle = _activeHandle != ResizeHandle.none ? _activeHandle : _hoveredHandle;

    switch (handle) {
      case ResizeHandle.topLeft:
      case ResizeHandle.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case ResizeHandle.topRight:
      case ResizeHandle.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case ResizeHandle.top:
      case ResizeHandle.bottom:
   return SystemMouseCursors.resizeUpDown;
      case ResizeHandle.left:
      case ResizeHandle.right:
        return SystemMouseCursors.resizeLeftRight;
  case ResizeHandle.none:
   return SystemMouseCursors.basic;
  }
  }
}

class _InteractiveFramePainter extends CustomPainter {
  final ui.Image frame;
  final double scaleX;
  final double scaleY;
  final bool showHandles;
  final ResizeHandle hoveredHandle;
  final ResizeHandle activeHandle;

  const _InteractiveFramePainter({
    required this.frame,
    required this.scaleX,
    required this.scaleY,
    required this.showHandles,
    required this.hoveredHandle,
    required this.activeHandle,
  });

  @override
  void paint(Canvas canvas, Size size) {
 // Calculate letterboxed video dimensions (same as _FramePainter)
    final imageAspect = frame.width / frame.height;
    final containerAspect = size.width / size.height;

    double baseVideoWidth, baseVideoHeight, baseOffsetX = 0, baseOffsetY = 0;

    if (imageAspect > containerAspect) {
      baseVideoWidth = size.width;
      baseVideoHeight = size.width / imageAspect;
 baseOffsetY = (size.height - baseVideoHeight) / 2;
    } else {
      baseVideoHeight = size.height;
 baseVideoWidth = size.height * imageAspect;
      baseOffsetX = (size.width - baseVideoWidth) / 2;
 }

    // Apply clip scaling
    final scaledWidth = baseVideoWidth * scaleX;
    final scaledHeight = baseVideoHeight * scaleY;

    // Center scaled video
    final offsetX = baseOffsetX + (baseVideoWidth - scaledWidth) / 2;
    final offsetY = baseOffsetY + (baseVideoHeight - scaledHeight) / 2;

    final destRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
    final srcRect = Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble());

    // Draw the frame
    canvas.drawImageRect(frame, srcRect, destRect, Paint());

    if (showHandles) {
      _drawSelectionBorder(canvas, destRect);
      _drawResizeHandles(canvas, destRect);
    }
  }

  void _drawSelectionBorder(Canvas canvas, Rect rect) {
    final borderPaint = Paint()
      ..color = AppColors.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(rect, borderPaint);
  }

  void _drawResizeHandles(Canvas canvas, Rect rect) {
    final handleSize = 12.0;
    
    final handles = [
      (ResizeHandle.topLeft, rect.topLeft),
    (ResizeHandle.top, Offset(rect.center.dx, rect.top)),
      (ResizeHandle.topRight, rect.topRight),
  (ResizeHandle.right, Offset(rect.right, rect.center.dy)),
      (ResizeHandle.bottomRight, rect.bottomRight),
      (ResizeHandle.bottom, Offset(rect.center.dx, rect.bottom)),
      (ResizeHandle.bottomLeft, rect.bottomLeft),
      (ResizeHandle.left, Offset(rect.left, rect.center.dy)),
    ];

    for (final (handle, position) in handles) {
      final isHovered = hoveredHandle == handle;
      final isActive = activeHandle == handle;

      final handlePaint = Paint()
   ..color = isActive || isHovered ? AppColors.accentBlue : Colors.white
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = AppColors.accentBlue
   ..style = PaintingStyle.stroke
 ..strokeWidth = 2;

      final handleRect = Rect.fromCenter(
        center: position,
        width: handleSize,
        height: handleSize,
    );

      canvas.drawRect(handleRect, handlePaint);
      canvas.drawRect(handleRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_InteractiveFramePainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.scaleX != scaleX ||
        oldDelegate.scaleY != scaleY ||
        oldDelegate.hoveredHandle != hoveredHandle ||
        oldDelegate.activeHandle != activeHandle;
  }
}

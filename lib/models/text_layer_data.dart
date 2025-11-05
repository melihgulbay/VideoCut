import 'package:flutter/material.dart';

enum TextAlignmentType {
  left,
  center,
  right,
}

class TextLayerData {
  final int layerId;
  final String text;
  final int trackIndex;
  final int startTimeMs;
  final int endTimeMs;
  
  // Position (0-1 normalized coordinates)
  final double x;
  final double y;
  
  // Size and style
  final int fontSize;
  final String fontFamily;
  
  // Color
  final Color textColor;
  final Color backgroundColor;
  
  // Transform
  final double rotation;  // degrees
  final double scale;
  final TextAlignmentType alignment;
  
  // Style flags
  final bool bold;
  final bool italic;
  final bool underline;
  final bool hasBackground;
  
  const TextLayerData({
  required this.layerId,
    this.text = '',
    this.trackIndex = 0,
    required this.startTimeMs,
    required this.endTimeMs,
    this.x = 0.5,
    this.y = 0.5,
    this.fontSize = 96, // Increased from 72 to 96 for better readability
    this.fontFamily = 'Arial',
    this.textColor = Colors.white,
    this.backgroundColor = Colors.transparent,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.alignment = TextAlignmentType.center,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.hasBackground = false,
  });
  
  int get durationMs => endTimeMs - startTimeMs;
  
  TextLayerData copyWith({
    int? layerId,
    String? text,
    int? trackIndex,
    int? startTimeMs,
    int? endTimeMs,
    double? x,
    double? y,
    int? fontSize,
    String? fontFamily,
    Color? textColor,
    Color? backgroundColor,
    double? rotation,
    double? scale,
    TextAlignmentType? alignment,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? hasBackground,
  }) {
    return TextLayerData(
      layerId: layerId ?? this.layerId,
      text: text ?? this.text,
      trackIndex: trackIndex ?? this.trackIndex,
      startTimeMs: startTimeMs ?? this.startTimeMs,
    endTimeMs: endTimeMs ?? this.endTimeMs,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      alignment: alignment ?? this.alignment,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      hasBackground: hasBackground ?? this.hasBackground,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
  other is TextLayerData &&
     runtimeType == other.runtimeType &&
    layerId == other.layerId &&
          text == other.text &&
   trackIndex == other.trackIndex &&
          startTimeMs == other.startTimeMs &&
          endTimeMs == other.endTimeMs;

  @override
  int get hashCode =>
      layerId.hashCode ^
      text.hashCode ^
      trackIndex.hashCode ^
startTimeMs.hashCode ^
    endTimeMs.hashCode;
}

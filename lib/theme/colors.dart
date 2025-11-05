import 'package:flutter/material.dart';

/// Modern cinematic color palette for VideoCut
/// Black, White, and Blue accent theme
class AppColors {
  // Primary Blacks
  static const primaryBlack = Color(0xFF0A0A0A);        // Deep black background
  static const secondaryBlack = Color(0xFF1A1A1A);      // Elevated surfaces
  static const tertiaryBlack = Color(0xFF242424);       // Cards/panels
  
  // Accent Blue
  static const accentBlue = Color(0xFF007BFF);   // Primary actions
  static const accentBlueHover = Color(0xFF0056D9);     // Hover states
  static const accentBlueLight = Color(0xFF4DA3FF);     // Highlights
  static const accentBlueDim = Color(0x33007BFF);       // Subtle backgrounds (20% opacity)
  static const accentBlueGlow = Color(0x66007BFF);   // Glow effects (40% opacity)
  
  // Text & Icons
  static const textPrimary = Color(0xFFFFFFFF);         // High contrast white
  static const textSecondary = Color(0xFFB0B0B0);       // Muted text
  static const textTertiary = Color(0xFF6B6B6B);        // Disabled/subtle
  
  // UI Elements
  static const dividerColor = Color(0xFF2A2A2A);  // Subtle separators
  static const borderColor = Color(0xFF333333);     // Card borders
  static const hoverOverlay = Color(0x0AFFFFFF);        // Hover highlight (4% white)
  static const activeOverlay = Color(0x1AFFFFFF);       // Active highlight (10% white)
  
  // Status Colors
  static const successGreen = Color(0xFF00C853);   // Success states
  static const warningOrange = Color(0xFFFF9800);       // Warnings
  static const errorRed = Color(0xFFFF5252);        // Errors
  static const infoBlue = Color(0xFF2196F3);        // Info messages
  
  // Track Type Colors (for timeline)
  static const trackText = Color(0xFF9C27B0);           // Purple for text tracks
  static const trackVideo = Color(0xFF2196F3);          // Blue for video tracks
  static const trackAudio = Color(0xFF00C853);    // Green for audio tracks
  
  // Transparency levels
  static const transparent = Color(0x00000000);
  static const blackOverlay50 = Color(0x80000000);      // 50% black overlay
  static const blackOverlay75 = Color(0xBF000000);      // 75% black overlay
}

import 'package:flutter/material.dart';

/// Shadow definitions for elevation and depth
class AppShadows {
  // Soft shadows for cards and panels
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  // Medium shadows for elevated components
  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  // Strong shadows for modals and overlays
  static List<BoxShadow> strong = [
BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
  
  // Glow effect for blue accent elements
  static List<BoxShadow> blueGlow = [
    BoxShadow(
      color: const Color(0xFF007BFF).withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 0),
      spreadRadius: 0,
    ),
  ];
  
  // Subtle inner shadow effect
  static List<BoxShadow> inner = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
  blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: -1,
    ),
  ];
  
  // No shadow
  static List<BoxShadow> none = [];
}

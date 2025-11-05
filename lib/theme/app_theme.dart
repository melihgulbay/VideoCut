import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

/// Complete Material 3 theme for VideoCut
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
  useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.accentBlue,
   onPrimary: AppColors.textPrimary,
      secondary: AppColors.accentBlueLight,
      onSecondary: AppColors.textPrimary,
        surface: AppColors.secondaryBlack,
    onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.tertiaryBlack,
     error: AppColors.errorRed,
    onError: AppColors.textPrimary,
        outline: AppColors.borderColor,
        outlineVariant: AppColors.dividerColor,
      ),
      
      // Background
    scaffoldBackgroundColor: AppColors.primaryBlack,
      canvasColor: AppColors.secondaryBlack,
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.secondaryBlack,
    foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
  titleTextStyle: AppTypography.headingMedium,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppSpacing.iconM,
        ),
      ),
      
      // Card
      cardTheme: const CardThemeData(
     color: AppColors.tertiaryBlack,
  elevation: 0,
        shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusL)),
        ),
        margin: EdgeInsets.all(AppSpacing.m),
 ),
  
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
  foregroundColor: AppColors.textPrimary,
          elevation: 0,
        padding: const EdgeInsets.symmetric(
       horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusM,
        ),
          textStyle: AppTypography.buttonMedium,
        ).copyWith(
          overlayColor: WidgetStateProperty.all(AppColors.accentBlueHover),
        ),
      ),
 
 // Text Button
      textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
          foregroundColor: AppColors.accentBlue,
       padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
      vertical: AppSpacing.s,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusM,
    ),
          textStyle: AppTypography.buttonMedium,
      ),
 ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
   foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderColor, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
  vertical: AppSpacing.s,
          ),
     shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusM,
  ),
     textStyle: AppTypography.buttonMedium,
   ),
      ),
      
   // Icon Button
      iconButtonTheme: IconButtonThemeData(
  style: IconButton.styleFrom(
       foregroundColor: AppColors.textPrimary,
          hoverColor: AppColors.hoverOverlay,
          highlightColor: AppColors.activeOverlay,
        ),
   ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
fillColor: AppColors.primaryBlack,
        border: OutlineInputBorder(
       borderRadius: AppSpacing.borderRadiusM,
borderSide: const BorderSide(color: AppColors.borderColor, width: 1),
        ),
     enabledBorder: OutlineInputBorder(
    borderRadius: AppSpacing.borderRadiusM,
          borderSide: const BorderSide(color: AppColors.borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusM,
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
    borderRadius: AppSpacing.borderRadiusM,
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
        ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
 vertical: AppSpacing.s,
        ),
        hintStyle: AppTypography.bodyMedium,
        labelStyle: AppTypography.labelMedium,
    ),
      
      // Slider
      sliderTheme: SliderThemeData(
    activeTrackColor: AppColors.accentBlue,
        inactiveTrackColor: AppColors.borderColor,
        thumbColor: AppColors.accentBlue,
        overlayColor: AppColors.accentBlueDim,
 trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
     return AppColors.textPrimary;
      }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue;
 }
          return AppColors.borderColor;
  }),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue;
          }
return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.borderColor, width: 2),
     shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXS),
   ),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerColor,
        thickness: AppSpacing.dividerThin,
  space: 0,
      ),
  
      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.tertiaryBlack,
     borderRadius: AppSpacing.borderRadiusM,
        border: Border.all(color: AppColors.borderColor, width: 1),
        ),
        textStyle: AppTypography.bodySmall.copyWith(
    color: AppColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
vertical: AppSpacing.xs,
      ),
     waitDuration: const Duration(milliseconds: 500),
      ),
 
      // Snackbar
    snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.tertiaryBlack,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusL,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog
      dialogTheme: const DialogThemeData(
   backgroundColor: AppColors.secondaryBlack,
shape: RoundedRectangleBorder(
   borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusL)),
     ),
  titleTextStyle: null, // Will use textTheme
        contentTextStyle: null, // Will use textTheme
   ),
      
      // Popup Menu
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.tertiaryBlack,
      shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusM,
          side: const BorderSide(color: AppColors.borderColor, width: 1),
   ),
        textStyle: AppTypography.bodyMedium,
    ),
      
      // Text Theme
      textTheme: TextTheme(
   displayLarge: AppTypography.headingLarge,
        displayMedium: AppTypography.headingMedium,
        displaySmall: AppTypography.headingSmall,
     bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
     bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
      
// Icon Theme
      iconTheme: const IconThemeData(
   color: AppColors.textPrimary,
     size: AppSpacing.iconM,
      ),
      
      // Font Family (fallback)
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }
}

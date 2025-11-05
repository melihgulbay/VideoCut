import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../theme/shadows.dart';

/// Modern button component with variants
enum StudioButtonVariant {
  primary,   // Blue filled
  secondary, // White outline
  ghost,     // Transparent, text only
  danger,    // Red filled
}

enum StudioButtonSize {
  small,
  medium,
  large,
}

class StudioButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final StudioButtonVariant variant;
  final StudioButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  
  const StudioButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.variant = StudioButtonVariant.primary,
    this.size = StudioButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
  });
  
  // Factory constructors for common button types
  factory StudioButton.primary({
    required VoidCallback? onPressed,
    String? label,
    IconData? icon,
    StudioButtonSize size = StudioButtonSize.medium,
    bool isLoading = false,
  }) {
    return StudioButton(
  onPressed: onPressed,
      label: label,
icon: icon,
      variant: StudioButtonVariant.primary,
      size: size,
      isLoading: isLoading,
    );
  }
  
factory StudioButton.secondary({
    required VoidCallback? onPressed,
    String? label,
    IconData? icon,
    StudioButtonSize size = StudioButtonSize.medium,
  }) {
    return StudioButton(
      onPressed: onPressed,
      label: label,
   icon: icon,
    variant: StudioButtonVariant.secondary,
   size: size,
  );
  }
  
  factory StudioButton.ghost({
    required VoidCallback? onPressed,
    String? label,
    IconData? icon,
    StudioButtonSize size = StudioButtonSize.medium,
  }) {
    return StudioButton(
      onPressed: onPressed,
  label: label,
      icon: icon,
      variant: StudioButtonVariant.ghost,
    size: size,
    );
  }

  @override
  State<StudioButton> createState() => _StudioButtonState();
}

class _StudioButtonState extends State<StudioButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  
  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
    cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
   onTapCancel: () => setState(() => _isPressed = false),
        onTap: isDisabled ? null : widget.onPressed,
    child: AnimatedContainer(
  duration: const Duration(milliseconds: 150),
  curve: Curves.easeOut,
        width: widget.fullWidth ? double.infinity : null,
    height: _getHeight(),
          padding: _getPadding(),
          decoration: _getDecoration(isDisabled),
          child: Row(
    mainAxisSize: MainAxisSize.min,
       mainAxisAlignment: MainAxisAlignment.center,
            children: [
    if (widget.isLoading)
         SizedBox(
width: _getIconSize(),
       height: _getIconSize(),
           child: CircularProgressIndicator(
           strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation(_getTextColor(isDisabled)),
   ),
 )
          else if (widget.icon != null)
        Icon(
       widget.icon,
             size: _getIconSize(),
             color: _getTextColor(isDisabled),
    ),
        if (widget.icon != null && widget.label != null)
       const SizedBox(width: AppSpacing.s),
              if (widget.label != null)
         Text(
  widget.label!,
    style: _getTextStyle().copyWith(
  color: _getTextColor(isDisabled),
         ),
    ),
            ],
          ),
        ),
      ),
    );
  }
  
  double _getHeight() {
    switch (widget.size) {
      case StudioButtonSize.small:
 return AppSpacing.buttonHeightS;
      case StudioButtonSize.medium:
        return AppSpacing.buttonHeightM;
      case StudioButtonSize.large:
        return AppSpacing.buttonHeightL;
    }
  }
  
  EdgeInsets _getPadding() {
    final horizontal = widget.size == StudioButtonSize.small 
      ? AppSpacing.s 
        : AppSpacing.m;
    return EdgeInsets.symmetric(horizontal: horizontal);
  }
  
  double _getIconSize() {
    switch (widget.size) {
      case StudioButtonSize.small:
        return AppSpacing.iconS;
      case StudioButtonSize.medium:
        return AppSpacing.iconM;
   case StudioButtonSize.large:
   return AppSpacing.iconL;
    }
  }
  
  TextStyle _getTextStyle() {
    switch (widget.size) {
      case StudioButtonSize.small:
        return AppTypography.buttonSmall;
      case StudioButtonSize.medium:
        return AppTypography.buttonMedium;
      case StudioButtonSize.large:
   return AppTypography.buttonLarge;
    }
  }
  
  BoxDecoration _getDecoration(bool isDisabled) {
    Color bgColor;
  Color? borderColor;
    List<BoxShadow> shadows = AppShadows.none;
    
    switch (widget.variant) {
      case StudioButtonVariant.primary:
        bgColor = isDisabled 
            ? AppColors.borderColor 
            : (_isPressed 
       ? AppColors.accentBlueHover 
    : (_isHovered 
        ? AppColors.accentBlueLight 
         : AppColors.accentBlue));
  if (!isDisabled && _isHovered) {
          shadows = AppShadows.blueGlow;
        }
      break;
        
  case StudioButtonVariant.secondary:
        bgColor = AppColors.transparent;
   borderColor = isDisabled 
   ? AppColors.borderColor 
        : (_isHovered ? AppColors.textPrimary : AppColors.borderColor);
        break;
     
      case StudioButtonVariant.ghost:
   bgColor = _isHovered 
   ? AppColors.hoverOverlay 
            : AppColors.transparent;
        break;
        
      case StudioButtonVariant.danger:
        bgColor = isDisabled 
  ? AppColors.borderColor 
            : (_isPressed 
                ? AppColors.errorRed.withOpacity(0.8) 
             : (_isHovered 
        ? AppColors.errorRed.withOpacity(0.9) 
           : AppColors.errorRed));
        break;
    }
    
    return BoxDecoration(
      color: bgColor,
      borderRadius: AppSpacing.borderRadiusM,
      border: borderColor != null 
     ? Border.all(color: borderColor, width: 1) 
 : null,
      boxShadow: shadows,
    );
  }
  
  Color _getTextColor(bool isDisabled) {
    if (isDisabled) {
      return AppColors.textTertiary;
    }
    
    switch (widget.variant) {
      case StudioButtonVariant.primary:
      case StudioButtonVariant.danger:
        return AppColors.textPrimary;
      case StudioButtonVariant.secondary:
      case StudioButtonVariant.ghost:
        return AppColors.textPrimary;
    }
  }
}

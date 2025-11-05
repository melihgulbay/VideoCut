import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/shadows.dart';

/// Modern elevated card component with consistent styling
class StudioCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? borderRadius;
  final List<BoxShadow>? shadows;
  final Border? border;
  final VoidCallback? onTap;
  
  const StudioCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.shadows,
    this.border,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
   color: backgroundColor ?? AppColors.tertiaryBlack,
     borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusL),
        boxShadow: shadows ?? AppShadows.soft,
 border: border ?? Border.all(
          color: AppColors.borderColor,
          width: 1,
   ),
      ),
      child: child,
    );
  
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusL),
        child: content,
      );
    }
    
    return content;
  }
}

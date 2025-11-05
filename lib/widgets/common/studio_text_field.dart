import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Modern text input field with consistent styling
class StudioTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final IconData? icon;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final String? errorText;
  final Widget? suffix;

  const StudioTextField({
    super.key,
    this.label,
    this.hint,
    this.icon,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onEditingComplete,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.maxLines = 1,
this.minLines,
    this.errorText,
    this.suffix,
  });

  @override
  State<StudioTextField> createState() => _StudioTextFieldState();
}

class _StudioTextFieldState extends State<StudioTextField> {
  bool _isFocused = false;
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
    _controller.dispose();
}
    super.dispose();
}
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
         style: AppTypography.labelMedium,
   ),
          const SizedBox(height: AppSpacing.s),
        ],
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
   child: AnimatedContainer(
 duration: const Duration(milliseconds: 200),
decoration: BoxDecoration(
     borderRadius: AppSpacing.borderRadiusM,
        border: Border.all(
       color: widget.errorText != null 
               ? AppColors.errorRed
       : (_isFocused ? AppColors.accentBlue : AppColors.borderColor),
        width: _isFocused ? 2 : 1,
          ),
      color: AppColors.primaryBlack,
        ),
   child: Row(
              children: [
           if (widget.icon != null) ...[
       Padding(
         padding: const EdgeInsets.only(left: AppSpacing.m),
        child: Icon(
     widget.icon,
  size: AppSpacing.iconM,
     color: _isFocused 
     ? AppColors.accentBlue 
     : AppColors.textSecondary,
    ),
     ),
   const SizedBox(width: AppSpacing.s),
    ],
   Expanded(
 child: TextField(
         controller: _controller,
        onChanged: widget.onChanged,
        onEditingComplete: widget.onEditingComplete,
        keyboardType: widget.keyboardType,
    inputFormatters: widget.inputFormatters,
   enabled: widget.enabled,
                    maxLines: widget.maxLines,
   minLines: widget.minLines,
        style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
          ),
           decoration: InputDecoration(
hintText: widget.hint,
     hintStyle: AppTypography.bodyMedium,
     border: InputBorder.none,
             contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
  vertical: AppSpacing.s,
     ),
          isDense: true,
       ),
      ),
    ),
 if (widget.suffix != null) ...[
    widget.suffix!,
      const SizedBox(width: AppSpacing.s),
       ],
              ],
         ),
),
     ),
      if (widget.errorText != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
         widget.errorText!,
       style: AppTypography.bodySmall.copyWith(
     color: AppColors.errorRed,
   ),
          ),
        ],
      ],
    );
  }
}

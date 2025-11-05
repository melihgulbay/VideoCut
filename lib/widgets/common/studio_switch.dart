import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Modern toggle switch with blue accent
class StudioSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final bool enabled;
  
  const StudioSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
   mainAxisSize: MainAxisSize.min,
  children: [
        Switch(
  value: value,
  onChanged: enabled ? onChanged : null,
     activeColor: AppColors.textPrimary,
   activeTrackColor: AppColors.accentBlue,
   inactiveThumbColor: AppColors.textTertiary,
      inactiveTrackColor: AppColors.borderColor,
   ),
        if (label != null) ...[
const SizedBox(width: AppSpacing.s),
        Text(
       label!,
            style: AppTypography.labelMedium.copyWith(
       color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
     ),
 ),
    ],
  ],
    );
    
    if (label != null && enabled) {
  return InkWell(
 onTap: () => onChanged(!value),
        borderRadius: AppSpacing.borderRadiusM,
   child: Padding(
          padding: const EdgeInsets.symmetric(
     vertical: AppSpacing.xs,
    ),
   child: content,
   ),
   );
 }
    
    return content;
  }
}

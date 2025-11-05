import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Modern slider with blue accent and value display
class StudioSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final String? label;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final int? divisions;
  final String Function(double)? valueFormatter;
  final bool showValue;
  
  const StudioSlider({
    super.key,
    required this.value,
required this.min,
    required this.max,
    required this.onChanged,
    this.label,
    this.onChangeEnd,
    this.divisions,
    this.valueFormatter,
    this.showValue = true,
  });

  @override
  State<StudioSlider> createState() => _StudioSliderState();
}

class _StudioSliderState extends State<StudioSlider> {
  bool _isDragging = false;
  
  String _formatValue(double value) {
    if (widget.valueFormatter != null) {
      return widget.valueFormatter!(value);
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
  if (widget.label != null)
   Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
     Text(
      widget.label!,
   style: AppTypography.labelMedium,
   ),
   if (widget.showValue)
 Text(
     _formatValue(widget.value),
               style: AppTypography.mono.copyWith(
          color: _isDragging ? AppColors.accentBlue : AppColors.textSecondary,
       ),
      ),
          ],
     ),
        if (widget.label != null) const SizedBox(height: AppSpacing.s),
     SliderTheme(
 data: SliderThemeData(
            activeTrackColor: AppColors.accentBlue,
     inactiveTrackColor: AppColors.borderColor,
            thumbColor: AppColors.accentBlue,
overlayColor: AppColors.accentBlueDim,
   trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
     overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
     child: Slider(
     value: widget.value,
      min: widget.min,
            max: widget.max,
   divisions: widget.divisions,
 onChanged: widget.onChanged,
            onChangeStart: (_) => setState(() => _isDragging = true),
            onChangeEnd: (value) {
              setState(() => _isDragging = false);
        widget.onChangeEnd?.call(value);
   },
   ),
 ),
      ],
    );
  }
}

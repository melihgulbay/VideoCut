import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/editor_provider.dart';
import '../../models/text_layer_data.dart';

class TextPropertiesPanel extends ConsumerStatefulWidget {
  final int layerId;

  const TextPropertiesPanel({super.key, required this.layerId});

  @override
ConsumerState<TextPropertiesPanel> createState() => _TextPropertiesPanelState();
}

class _TextPropertiesPanelState extends ConsumerState<TextPropertiesPanel> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final editorNotifier = ref.read(editorProvider.notifier);
    
    final layer = editorState.textLayers.firstWhere(
      (l) => l.layerId == widget.layerId,
      orElse: () => TextLayerData(layerId: -1, startTimeMs: 0, endTimeMs: 0),
  );

    if (layer.layerId == -1) {
      return Container(
        color: const Color(0xFF2D2D2D),
        child: const Center(child: Text('Text layer not found')),
      );
  }

    if (_textController.text != layer.text) {
      _textController.text = layer.text;
 _textController.selection = TextSelection.fromPosition(
  TextPosition(offset: _textController.text.length),
      );
    }

    return Container(
      color: const Color(0xFF2D2D2D),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
     child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
    // Header
   Row(
       children: [
         const Icon(Icons.text_fields, color: Colors.blue),
             const SizedBox(width: 8),
       const Text(
        'Text Properties',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
          const Spacer(),
        IconButton(
           icon: const Icon(Icons.delete, color: Colors.red),
     tooltip: 'Delete',
          onPressed: () {
             editorNotifier.removeTextLayer(widget.layerId);
   },
        ),
          ],
            ),
            const Divider(height: 24),

            // Text Content
   const Text('Text', style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
       TextField(
       controller: _textController,
              decoration: const InputDecoration(
      hintText: 'Enter text...',
  border: OutlineInputBorder(),
          filled: true,
     fillColor: Colors.black26,
        ),
      maxLines: 3,
     onChanged: (value) {
       editorNotifier.updateTextLayer(
          widget.layerId,
          layer.copyWith(text: value),
        );
       },
     ),
            const SizedBox(height: 16),

            // Font Size
            const Text('Font Size', style: TextStyle(fontWeight: FontWeight.bold)),
    Slider(
       value: layer.fontSize.toDouble(),
       min: 12,
       max: 200,
         divisions: 188,
    label: layer.fontSize.toString(),
       onChanged: (value) {
      editorNotifier.updateTextLayer(
            widget.layerId,
     layer.copyWith(fontSize: value.toInt()),
   );
       },
            ),
          const SizedBox(height: 16),

       // Text Color
            const Text('Text Color', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
            Row(
          children: [
           Expanded(
     child: GestureDetector(
                 onTap: () => _showColorPicker(context, layer.textColor, (color) {
         editorNotifier.updateTextLayer(
                widget.layerId,
       layer.copyWith(textColor: color),
  );
    }),
        child: Container(
 height: 50,
        decoration: BoxDecoration(
       color: layer.textColor,
             border: Border.all(color: Colors.white, width: 2),
   borderRadius: BorderRadius.circular(8),
       ),
          child: const Center(
              child: Text(
         'Pick Color',
       style: TextStyle(
  color: Colors.white,
fontWeight: FontWeight.bold,
      shadows: [Shadow(blurRadius: 4)],
         ),
       ),
           ),
           ),
   ),
      ),
   ],
     ),
         const SizedBox(height: 16),

 // Background Toggle
 Row(
      children: [
     const Text('Background', style: TextStyle(fontWeight: FontWeight.bold)),
         const Spacer(),
 Switch(
    value: layer.hasBackground,
        onChanged: (value) {
       editorNotifier.updateTextLayer(
      widget.layerId,
        layer.copyWith(hasBackground: value),
           );
     },
        ),
       ],
),
  if (layer.hasBackground) ...[
       const SizedBox(height: 8),
       GestureDetector(
         onTap: () => _showColorPicker(context, layer.backgroundColor, (color) {
  editorNotifier.updateTextLayer(
               widget.layerId,
             layer.copyWith(backgroundColor: color),
      );
  }),
child: Container(
       height: 50,
    decoration: BoxDecoration(
            color: layer.backgroundColor,
        border: Border.all(color: Colors.white, width: 2),
       borderRadius: BorderRadius.circular(8),
           ),
 child: const Center(
  child: Text(
  'Background Color',
             style: TextStyle(
color: Colors.white,
                fontWeight: FontWeight.bold,
        shadows: [Shadow(blurRadius: 4)],
        ),
        ),
       ),
          ),
       ),
      ],
         const SizedBox(height: 16),

  // Style Toggles
    const Text('Style', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
            Wrap(
      spacing: 8,
       children: [
     FilterChip(
  label: const Text('Bold'),
     selected: layer.bold,
        onSelected: (value) {
            editorNotifier.updateTextLayer(
      widget.layerId,
               layer.copyWith(bold: value),
             );
      },
        ),
  FilterChip(
label: const Text('Italic'),
           selected: layer.italic,
     onSelected: (value) {
          editorNotifier.updateTextLayer(
               widget.layerId,
    layer.copyWith(italic: value),
      );
  },
       ),
    FilterChip(
          label: const Text('Underline'),
      selected: layer.underline,
      onSelected: (value) {
        editorNotifier.updateTextLayer(
  widget.layerId,
         layer.copyWith(underline: value),
     );
    },
             ),
       ],
            ),
            const SizedBox(height: 16),

       // Alignment
     const Text('Alignment', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
  SegmentedButton<TextAlignmentType>(
  segments: const [
    ButtonSegment(
         value: TextAlignmentType.left,
    icon: Icon(Icons.format_align_left),
           ),
 ButtonSegment(
              value: TextAlignmentType.center,
            icon: Icon(Icons.format_align_center),
                ),
        ButtonSegment(
     value: TextAlignmentType.right,
  icon: Icon(Icons.format_align_right),
         ),
       ],
   selected: {layer.alignment},
              onSelectionChanged: (Set<TextAlignmentType> newSelection) {
       editorNotifier.updateTextLayer(
         widget.layerId,
       layer.copyWith(alignment: newSelection.first),
      );
 },
         ),
            const SizedBox(height: 16),

    // Scale
    const Text('Scale', style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
  value: layer.scale,
  min: 0.5,
       max: 3.0,
              divisions: 50,
       label: '${(layer.scale * 100).toInt()}%',
   onChanged: (value) {
       editorNotifier.updateTextLayer(
       widget.layerId,
     layer.copyWith(scale: value),
                );
         },
          ),
 const SizedBox(height: 16),

    // Rotation
         const Text('Rotation', style: TextStyle(fontWeight: FontWeight.bold)),
    Slider(
     value: layer.rotation,
          min: -180,
   max: 180,
              divisions: 360,
              label: '${layer.rotation.toInt()}°',
       onChanged: (value) {
       editorNotifier.updateTextLayer(
        widget.layerId,
     layer.copyWith(rotation: value),
       );
       },
            ),
            const SizedBox(height: 16),

            // Duration
  const Text('Duration', style: TextStyle(fontWeight: FontWeight.bold)),
     const SizedBox(height: 8),
     Text(
          '${_formatDuration(layer.startTimeMs)} - ${_formatDuration(layer.endTimeMs)}',
       style: TextStyle(color: Colors.grey[400]),
          ),
          ],
        ),
      ),
 );
  }

  void _showColorPicker(BuildContext context, Color currentColor, Function(Color) onColorChanged) {
    showDialog(
    context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick Color'),
        content: SingleChildScrollView(
       child: Wrap(
         spacing: 8,
            runSpacing: 8,
          children: [
              Colors.white,
       Colors.black,
              Colors.red,
 Colors.green,
    Colors.blue,
              Colors.yellow,
    Colors.orange,
     Colors.purple,
        Colors.pink,
              Colors.teal,
Colors.cyan,
              Colors.lime,
    Colors.brown,
     Colors.grey,
  Colors.transparent,
     ].map((color) {
      return GestureDetector(
        onTap: () {
     onColorChanged(color);
          Navigator.pop(context);
         },
     child: Container(
            width: 50,
           height: 50,
   decoration: BoxDecoration(
          color: color,
            border: Border.all(
      color: color == currentColor ? Colors.white : Colors.grey,
width: color == currentColor ? 3 : 1,
            ),
  borderRadius: BorderRadius.circular(8),
         ),
         ),
              );
     }).toList(),
   ),
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

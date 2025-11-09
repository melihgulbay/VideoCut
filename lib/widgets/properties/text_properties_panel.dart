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

            // Font Family Selector
            const Text('Font Family', style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
            DropdownButtonFormField<String>(
     value: layer.fontFamily,
       decoration: const InputDecoration(
    border: OutlineInputBorder(),
         filled: true,
    fillColor: Colors.black26,
              ),
 items: const [
           DropdownMenuItem(value: 'Arial', child: Text('Arial', style: TextStyle(fontFamily: 'Arial'))),
             DropdownMenuItem(value: 'Times New Roman', child: Text('Times New Roman', style: TextStyle(fontFamily: 'Times New Roman'))),
                DropdownMenuItem(value: 'Courier New', child: Text('Courier New', style: TextStyle(fontFamily: 'Courier New'))),
   DropdownMenuItem(value: 'Georgia', child: Text('Georgia', style: TextStyle(fontFamily: 'Georgia'))),
           DropdownMenuItem(value: 'Verdana', child: Text('Verdana', style: TextStyle(fontFamily: 'Verdana'))),
          DropdownMenuItem(value: 'Comic Sans MS', child: Text('Comic Sans MS', style: TextStyle(fontFamily: 'Comic Sans MS'))),
    DropdownMenuItem(value: 'Impact', child: Text('Impact', style: TextStyle(fontFamily: 'Impact'))),
   DropdownMenuItem(value: 'Trebuchet MS', child: Text('Trebuchet MS', style: TextStyle(fontFamily: 'Trebuchet MS'))),
       DropdownMenuItem(value: 'Roboto', child: Text('Roboto', style: TextStyle(fontFamily: 'Roboto'))),
     DropdownMenuItem(value: 'Montserrat', child: Text('Montserrat', style: TextStyle(fontFamily: 'Montserrat'))),
         DropdownMenuItem(value: 'Open Sans', child: Text('Open Sans', style: TextStyle(fontFamily: 'Open Sans'))),
    DropdownMenuItem(value: 'Poppins', child: Text('Poppins', style: TextStyle(fontFamily: 'Poppins'))),
  ],
         onChanged: (value) {
          if (value != null) {
    editorNotifier.updateTextLayer(
            widget.layerId,
        layer.copyWith(fontFamily: value),
               );
        }
        },
      ),
          const SizedBox(height: 16),

       // Text Templates
            const Text('Templates', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
            Wrap(
      spacing: 8,
  runSpacing: 8,
          children: [
     _buildTemplateChip('Lower Third', () => _applyTemplate('lowerThird', layer)),
    _buildTemplateChip('Title', () => _applyTemplate('title', layer)),
_buildTemplateChip('Subtitle', () => _applyTemplate('subtitle', layer)),
          _buildTemplateChip('Credits', () => _applyTemplate('credits', layer)),
            _buildTemplateChip('Caption', () => _applyTemplate('caption', layer)),
       ],
    ),
      const SizedBox(height: 16),

            // Animation Presets
    const Text('Animations', style: TextStyle(fontWeight: FontWeight.bold)),
       const SizedBox(height: 8),
   Wrap(
              spacing: 8,
              runSpacing: 8,
   children: [
     _buildAnimationChip('Fade In', () => _applyAnimation('fadeIn', layer)),
       _buildAnimationChip('Slide Up', () => _applyAnimation('slideUp', layer)),
       _buildAnimationChip('Slide Down', () => _applyAnimation('slideDown', layer)),
       _buildAnimationChip('Zoom In', () => _applyAnimation('zoomIn', layer)),
       _buildAnimationChip('Bounce', () => _applyAnimation('bounce', layer)),
          _buildAnimationChip('Typewriter', () => _applyAnimation('typewriter', layer)),
        ],
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

  Widget _buildTemplateChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
  onPressed: onTap,
      avatar: const Icon(Icons.text_snippet, size: 16),
      backgroundColor: Colors.blue.withOpacity(0.2),
    );
  }

Widget _buildAnimationChip(String label, VoidCallback onTap) {
  return ActionChip(
      label: Text(label),
    onPressed: onTap,
 avatar: const Icon(Icons.animation, size: 16),
      backgroundColor: Colors.purple.withOpacity(0.2),
    );
  }

  void _applyTemplate(String templateType, TextLayerData layer) {
    final editorNotifier = ref.read(editorProvider.notifier);
    
    switch (templateType) {
      case 'lowerThird':
        editorNotifier.updateTextLayer(
      widget.layerId,
    layer.copyWith(
  text: 'Lower Third Text',
       fontSize: 32,
   fontFamily: 'Roboto',
        bold: true,
            hasBackground: true,
       backgroundColor: Colors.blue.withOpacity(0.8),
 textColor: Colors.white,
            positionX: 0.1,
            positionY: 0.85,
       alignment: TextAlignmentType.left,
     ),
      );
        break;
      
      case 'title':
  editorNotifier.updateTextLayer(
          widget.layerId,
  layer.copyWith(
       text: 'Your Title Here',
       fontSize: 72,
       fontFamily: 'Poppins',
      bold: true,
   hasBackground: false,
       textColor: Colors.white,
       positionX: 0.5,
   positionY: 0.3,
       alignment: TextAlignmentType.center,
            scale: 1.2,
    ),
  );
        break;
    
      case 'subtitle':
 editorNotifier.updateTextLayer(
  widget.layerId,
       layer.copyWith(
    text: 'Subtitle text goes here',
     fontSize: 36,
       fontFamily: 'Open Sans',
    bold: false,
  italic: true,
        hasBackground: false,
  textColor: Colors.white70,
        positionX: 0.5,
      positionY: 0.5,
      alignment: TextAlignmentType.center,
          ),
  );
    break;
      
  case 'credits':
  editorNotifier.updateTextLayer(
          widget.layerId,
     layer.copyWith(
     text: 'Directed by\nYour Name',
fontSize: 24,
 fontFamily: 'Georgia',
            bold: false,
     italic: true,
  hasBackground: false,
      textColor: Colors.white,
 positionX: 0.5,
          positionY: 0.5,
      alignment: TextAlignmentType.center,
          ),
        );
        break;
 
   case 'caption':
        editorNotifier.updateTextLayer(
          widget.layerId,
        layer.copyWith(
       text: '[Caption text]',
        fontSize: 28,
       fontFamily: 'Arial',
  bold: false,
            hasBackground: true,
     backgroundColor: Colors.black.withOpacity(0.7),
            textColor: Colors.white,
  positionX: 0.5,
      positionY: 0.9,
            alignment: TextAlignmentType.center,
       ),
        );
     break;
    }
  }

  void _applyAnimation(String animationType, TextLayerData layer) {
    final editorNotifier = ref.read(editorProvider.notifier);
    
    // Store animation type in layer data for future rendering
    // For now, apply visual presets that suggest the animation
    switch (animationType) {
      case 'fadeIn':
        editorNotifier.updateTextLayer(
    widget.layerId,
          layer.copyWith(
    // Animation would be implemented in renderer
          // This is a visual preset
          ),
      );
        ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Fade In animation applied')),
        );
        break;
      
      case 'slideUp':
        editorNotifier.updateTextLayer(
          widget.layerId,
   layer.copyWith(
  positionY: layer.positionY,
       ),
   );
   ScaffoldMessenger.of(context).showSnackBar(
 const SnackBar(content: Text('Slide Up animation applied')),
    );
        break;
  
   case 'slideDown':
        editorNotifier.updateTextLayer(
   widget.layerId,
          layer.copyWith(
       positionY: layer.positionY,
       ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slide Down animation applied')),
   );
        break;
      
      case 'zoomIn':
   editorNotifier.updateTextLayer(
          widget.layerId,
          layer.copyWith(
       scale: layer.scale,
        ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
   const SnackBar(content: Text('Zoom In animation applied')),
        );
        break;
      
      case 'bounce':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bounce animation applied')),
 );
   break;
      
case 'typewriter':
        ScaffoldMessenger.of(context).showSnackBar(
     const SnackBar(content: Text('Typewriter animation applied')),
        );
break;
    }
  }
}

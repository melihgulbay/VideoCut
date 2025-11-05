import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'export_wrapper.dart';
import '../providers/editor_provider.dart';
import '../widgets/video_preview.dart';

class ExportDialog extends ConsumerStatefulWidget {
  final ExportSettingsData? initialSettings;

  const ExportDialog({super.key, this.initialSettings});

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  late TextEditingController _outputPathController;
  late TextEditingController _bitrateController;
  late TextEditingController _frameRateController;
  
  String _selectedCodec = 'h264';
  final List<String> _codecs = ['h264', 'h265', 'vp9', 'av1'];
  
  @override
  void initState() {
    super.initState();
    
    final settings = widget.initialSettings ?? ExportSettingsData(outputPath: '');
    
  _outputPathController = TextEditingController(text: settings.outputPath);
    _bitrateController = TextEditingController(text: (settings.bitrate ~/ 1000000).toString());
    _frameRateController = TextEditingController(text: settings.frameRate.toString());
    _selectedCodec = settings.codec;
  }

  @override
  void dispose() {
    _outputPathController.dispose();
    _bitrateController.dispose();
    _frameRateController.dispose();
    super.dispose();
  }

  Future<void> _selectOutputPath() async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Video',
      fileName: 'output.mp4',
    type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
    );

    if (result != null) {
      setState(() {
        // Ensure the path has an extension
  String outputPath = result;
        if (!outputPath.endsWith('.mp4') && 
         !outputPath.endsWith('.mov') && 
     !outputPath.endsWith('.avi') &&
         !outputPath.endsWith('.mkv')) {
          outputPath = '$outputPath.mp4'; // Add .mp4 if no extension
}
        _outputPathController.text = outputPath;
      });
    }
  }

  ExportSettingsData? _buildSettings() {
    if (_outputPathController.text.isEmpty) {
return null;
    }

    // Get dimensions from editor preview settings (not user input)
    final editorState = ref.read(editorProvider);

  try {
      return ExportSettingsData(
        outputPath: _outputPathController.text,
        width: editorState.exportWidth,   // From preview aspect ratio
        height: editorState.exportHeight, // From preview quality
      bitrate: int.parse(_bitrateController.text) * 1000000,
        frameRate: double.parse(_frameRateController.text),
  codec: _selectedCodec,
        audioBitrate: 192000,
     audioSampleRate: 48000,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700), // Limit max height
        padding: const EdgeInsets.all(24),
    child: SingleChildScrollView( // Make it scrollable
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
       children: [
  // Header
  Row(
           children: [
       const Icon(Icons.file_download, color: Colors.blue, size: 32),
       const SizedBox(width: 12),
          const Text(
           'Export Video',
         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
   const Spacer(),
   IconButton(
      icon: const Icon(Icons.close),
   onPressed: () => Navigator.of(context).pop(),
      ),
      ],
    ),
     const Divider(height: 32),

              // NEW: Current Preview Settings Info
    Container(
              padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
    color: Colors.blue.withOpacity(0.1),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
    child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
 children: [
        const Row(
      children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
     SizedBox(width: 8),
      Text(
          'Export Resolution (from Preview)',
   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
         ),
    ],
          ),
     const SizedBox(height: 12),
    Row(
 children: [
     Expanded(
    child: _InfoItem(
      label: 'Aspect Ratio',
   value: ref.read(editorProvider).aspectRatio.label,
     ),
           ),
  Expanded(
      child: _InfoItem(
         label: 'Quality',
 value: ref.read(editorProvider).quality.label,
           ),
       ),
],
    ),
 const SizedBox(height: 8),
          _InfoItem(
 label: 'Resolution',
 value: '${ref.read(editorProvider).exportWidth}x${ref.read(editorProvider).exportHeight}',
   ),
            const SizedBox(height: 8),
            const Text(
    'Change aspect ratio and quality in the preview to adjust export resolution',
          style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
         ),
   ],
     ),
     ),
 const SizedBox(height: 24),

        // Output path
 const Text('Output File', style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
 Row(
     children: [
  Expanded(
    child: TextField(
    controller: _outputPathController,
    decoration: InputDecoration(
       hintText: 'Select output location...',
            border: const OutlineInputBorder(),
        filled: true,
      fillColor: Colors.black26,
          ),
readOnly: true,
        ),
     ),
      const SizedBox(width: 8),
          ElevatedButton.icon(
  onPressed: _selectOutputPath,
       icon: const Icon(Icons.folder_open),
        label: const Text('Browse'),
   ),
 ],
      ),
const SizedBox(height: 24),

  // Codec and settings
  Row(
      children: [
      Expanded(
        child: Column(
   crossAxisAlignment: CrossAxisAlignment.start,
        children: [
     const Text('Codec', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
  DropdownButtonFormField<String>(
        value: _selectedCodec,
 decoration: const InputDecoration(
                 border: OutlineInputBorder(),
                   filled: true,
         fillColor: Colors.black26,
         ),
      items: _codecs.map((codec) {
         return DropdownMenuItem(value: codec, child: Text(codec.toUpperCase()));
          }).toList(),
           onChanged: (value) {
   if (value != null) setState(() => _selectedCodec = value);
   },
         ),
               ],
         ),
       ),
         const SizedBox(width: 16),
         Expanded(
 child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
children: [
            const Text('Bitrate (Mbps)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
         controller: _bitrateController,
       decoration: const InputDecoration(
      border: OutlineInputBorder(),
      filled: true,
     fillColor: Colors.black26,
          ),
            keyboardType: TextInputType.number,
        ),
          ],
        ),
         ),
          ],
   ),
  const SizedBox(height: 24),

     // Frame rate
              const Text('Frame Rate', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
       TextField(
                controller: _frameRateController,
      decoration: const InputDecoration(
                labelText: 'FPS',
        border: OutlineInputBorder(),
             filled: true,
   fillColor: Colors.black26,
       ),
  keyboardType: TextInputType.number,
           ),
const SizedBox(height: 32),

   // Actions
 Row(
          mainAxisAlignment: MainAxisAlignment.end,
    children: [
          TextButton(
      onPressed: () => Navigator.of(context).pop(),
           child: const Text('Cancel'),
      ),
          const SizedBox(width: 16),
         ElevatedButton.icon(
                onPressed: () {
   final settings = _buildSettings();
   if (settings != null) {
   Navigator.of(context).pop(settings);
     } else {
        ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
    content: Text('Please fill all fields correctly'),
  backgroundColor: Colors.red,
            ),
   );
     }
    },
         icon: const Icon(Icons.check),
        label: const Text('Start Export'),
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
 ),
    ),
       ],
     ),
  ],
          ),
        ),
 ),
    );
  }
}


/// Helper widget to display info items
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
     ),
        const SizedBox(height: 4),
        Text(
   value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

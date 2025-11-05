import 'package:flutter/material.dart';
import 'dart:async';
import 'export_wrapper.dart';

class ExportProgressDialog extends StatefulWidget {
  final VideoExporter exporter;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const ExportProgressDialog({
    super.key,
    required this.exporter,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<ExportProgressDialog> createState() => _ExportProgressDialogState();
}

class _ExportProgressDialogState extends State<ExportProgressDialog> {
  Timer? _progressTimer;
  double _progress = 0.0;
  bool _isExporting = true;

  @override
  void initState() {
    super.initState();
    _startProgressTracking();
  }

  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final progress = widget.exporter.getProgress();
      final isExporting = widget.exporter.isExporting;

      setState(() {
        _progress = progress;
        _isExporting = isExporting;
      });

      // Check if export completed
      if (!isExporting || progress >= 0.99) {
        timer.cancel();
        if (progress >= 0.99) {
          // Export completed successfully - wait a bit then close
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.of(context).pop(true);
              widget.onComplete();
            }
          });
        }
      }
    });
  }

  void _cancelExport() {
    widget.exporter.cancel();
    widget.onCancel();
    Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_progress * 100).toInt();

    return WillPopScope(
      onWillPop: () async {
        // Prevent closing dialog by tapping outside
        return false;
      },
      child: Dialog(
        backgroundColor: const Color(0xFF2D2D2D),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.video_file, color: Colors.blue, size: 32),
                  const SizedBox(width: 12),
                  const Text(
                    'Exporting Video',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Progress indicator
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Status message
              Text(
                _isExporting
                    ? 'Encoding video... Please wait.'
                    : _progress >= 1.0
                        ? 'Export completed successfully!'
                        : 'Export cancelled',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Actions
              if (_isExporting)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cancelExport,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

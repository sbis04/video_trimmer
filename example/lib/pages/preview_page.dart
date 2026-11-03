import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';

/// Shows the trimmed result, and — for video output — the duration actually
/// written next to the duration that was asked for. A mismatch here is the
/// quickest way to spot keyframe snapping in the native trimmer.
class PreviewPage extends StatefulWidget {
  const PreviewPage({
    super.key,
    required this.path,
    required this.outputType,
    required this.requestedRange,
  });

  final String path;
  final OutputType outputType;
  final Duration requestedRange;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  VideoPlayerController? _controller;
  int? _fileSizeBytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final file = File(widget.path);
    if (file.existsSync()) {
      _fileSizeBytes = await file.length();
    }
    if (widget.outputType == OutputType.video) {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String get _sizeLabel {
    final bytes = _fileSizeBytes;
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} kB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final actual = controller?.value.duration;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Preview')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: widget.outputType == OutputType.gif
                  ? Image.file(File(widget.path))
                  : controller == null
                      ? const CircularProgressIndicator()
                      : AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white10,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(label: 'output', value: widget.outputType.name),
                _Row(label: 'size', value: _sizeLabel),
                _Row(
                  label: 'requested',
                  value: '${widget.requestedRange.inMilliseconds} ms',
                ),
                if (actual != null)
                  _Row(
                    label: 'actual',
                    value: '${actual.inMilliseconds} ms',
                    highlight: (actual.inMilliseconds -
                                widget.requestedRange.inMilliseconds)
                            .abs() >
                        200,
                  ),
                const SizedBox(height: 8),
                Text(
                  widget.path,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: highlight ? Colors.orangeAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

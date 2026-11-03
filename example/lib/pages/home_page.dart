import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/trimmer_config.dart';
import 'config_page.dart';
import 'trimmer_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TrimmerConfig _config = const TrimmerConfig();
  bool _preparingSample = false;

  /// The last selection per file, restored through `initialStartValue` /
  /// `initialEndValue` when the same video is opened again. A real app would
  /// persist this.
  final Map<String, TrimRange> _savedRanges = {};

  Future<void> _openTrimmer(File file) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrimmerPage(
          file: file,
          config: _config,
          savedRange: _savedRanges[file.path],
          onRangeSaved: (range) => _savedRanges[file.path] = range,
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    final picked = await FilePicker.pickFile(type: FileType.video);
    final path = picked?.path;
    if (path == null) return;
    await _openTrimmer(File(path));
  }

  /// Copies the bundled 30-second clip out of the asset bundle so the trimmer
  /// has a real file to work with. Handy for trying options without going
  /// through the picker every time.
  Future<void> _useSample() async {
    setState(() => _preparingSample = true);
    try {
      final bytes = await rootBundle.load('assets/sample.mp4');
      final dir = await getTemporaryDirectory();
      // On macOS this is a per-app Caches folder that may not exist yet.
      await dir.create(recursive: true);
      final file = File('${dir.path}/sample.mp4');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await _openTrimmer(file);
    } finally {
      if (mounted) setState(() => _preparingSample = false);
    }
  }

  Future<void> _openConfig() async {
    final updated = await Navigator.of(context).push<TrimmerConfig>(
      MaterialPageRoute(builder: (_) => ConfigPage(config: _config)),
    );
    if (updated != null) setState(() => _config = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Trimmer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Customization',
            onPressed: _openConfig,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.movie_creation_outlined,
                    size: 64, color: Color(0xFFF9A825)),
                const SizedBox(height: 24),
                const Text(
                  'Pick a video, or start from the bundled 30-second sample.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  key: const Key('load_video'),
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library_outlined),
                  label: const Text('LOAD VIDEO'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('use_sample'),
                  onPressed: _preparingSample ? null : _useSample,
                  icon: _preparingSample
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_circle_outline),
                  label: const Text('USE SAMPLE VIDEO'),
                ),
                const SizedBox(height: 32),
                _ConfigSummary(config: _config, onTap: _openConfig),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact readout of the options currently in force, so it's obvious what
/// the trimmer will be built with.
class _ConfigSummary extends StatelessWidget {
  const _ConfigSummary({required this.config, required this.onTap});

  final TrimmerConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      'type: ${config.viewerType.name}',
      'maxVideoLength: ${config.maxVideoLengthSeconds}s',
      'area: ${config.areaStyle.label}',
      'output: ${config.outputType.name}',
      'manual scroll: ${config.allowManualScroll ? 'on' : 'off'}',
      if (!config.attachCallbacks) 'callbacks: omitted',
    ];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'CURRENT CONFIG',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF9A825),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    size: 18, color: Colors.white38),
              ],
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (line) => Text(
                line,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  fontFamily: 'monospace',
                  color: Colors.white60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

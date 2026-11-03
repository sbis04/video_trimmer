import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

import '../models/trimmer_config.dart';
import 'config_page.dart';
import 'preview_page.dart';

/// A trim selection in milliseconds, as reported by `onChangeStart` /
/// `onChangeEnd`.
typedef TrimRange = ({double start, double end});

class TrimmerPage extends StatefulWidget {
  const TrimmerPage({
    super.key,
    required this.file,
    required this.config,
    this.savedRange,
    this.onRangeSaved,
  });

  final File file;
  final TrimmerConfig config;

  /// A selection to restore, e.g. from the last time this file was open.
  final TrimRange? savedRange;

  /// Called with the final selection when the page closes.
  final ValueChanged<TrimRange>? onRangeSaved;

  @override
  State<TrimmerPage> createState() => _TrimmerPageState();
}

class _TrimmerPageState extends State<TrimmerPage> {
  final Trimmer _trimmer = Trimmer();

  late TrimmerConfig _config = widget.config;

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;

  /// What the next TrimViewer starts with: the saved range on first build,
  /// then the live selection whenever the viewer is rebuilt for a new config.
  late TrimRange? _restore = widget.savedRange;
  bool _looping = false;
  double _speed = 1.0;
  static const _speeds = [1.0, 1.5, 2.0, 0.5];
  bool _saving = false;
  bool _thumbnailsLoaded = false;

  /// Bumped whenever the config changes, to force a fresh `TrimViewer` rather
  /// than trying to mutate one in place.
  int _viewerGeneration = 0;

  @override
  void initState() {
    super.initState();
    _trimmer.loadVideo(videoFile: widget.file);
  }

  bool get _hasSelection => _endValue > _startValue;

  @override
  void dispose() {
    if (_hasSelection) {
      widget.onRangeSaved?.call((start: _startValue, end: _endValue));
    }
    _trimmer.dispose();
    super.dispose();
  }

  Future<void> _openConfig() async {
    final updated = await Navigator.of(context).push<TrimmerConfig>(
      MaterialPageRoute(builder: (_) => ConfigPage(config: _config)),
    );
    if (updated == null) return;
    setState(() {
      if (_hasSelection) _restore = (start: _startValue, end: _endValue);
      _config = updated;
      _thumbnailsLoaded = false;
      _viewerGeneration++;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      outputType: _config.outputType,
      storageDir: _config.storageDir,
      videoFolderName:
          _config.videoFolderName.isEmpty ? null : _config.videoFolderName,
      videoFileName:
          _config.customFileName.isEmpty ? null : _config.customFileName,
      fpsGIF: _config.fpsGIF,
      scaleGIF: _config.scaleGIF,
      qualityGIF: _config.qualityGIF,
      onSave: (outputPath) {
        if (!mounted) return;
        setState(() => _saving = false);
        if (outputPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trimming failed.')),
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PreviewPage(
              path: outputPath,
              outputType: _config.outputType,
              requestedRange: Duration(
                milliseconds: (_endValue - _startValue).round(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Trimmer'),
        actions: [
          IconButton(
            key: const Key('open_config'),
            icon: const Icon(Icons.tune),
            tooltip: 'Customization',
            onPressed: _openConfig,
          ),
          IconButton(
            key: const Key('save_video'),
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save',
            onPressed: _saving ? null : _save,
          ),
        ],
        bottom: _saving
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(_config.videoPadding),
                child: VideoViewer(
                  trimmer: _trimmer,
                  borderColor: _config.videoBorderColor,
                  borderWidth: _config.videoBorderWidth,
                  padding: EdgeInsets.all(_config.videoPadding),
                ),
              ),
            ),
            _SelectionReadout(
              startMs: _startValue,
              endMs: _endValue,
              thumbnailsLoaded: _thumbnailsLoaded,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: TrimViewer(
                key: ValueKey(_viewerGeneration),
                trimmer: _trimmer,
                viewerHeight: _config.viewerHeight,
                viewerWidth: MediaQuery.of(context).size.width - 16,
                type: _config.viewerType,
                maxVideoLength: _config.maxVideoLength,
                minVideoLength: _config.minVideoLength,
                paddingFraction: _config.paddingFraction,
                showDuration: _config.showDuration,
                durationStyle: _config.durationStyle,
                durationTextStyle: _config.durationTextStyle,
                editorProperties: _config.editorProperties,
                areaProperties: _config.areaProperties,
                initialStartValue: _restore?.start,
                initialEndValue: _restore?.end,
                onThumbnailLoadingComplete: () {
                  // Deferred because the package can fire this while the tree
                  // is locked, and setState would throw.
                  if (!mounted || _thumbnailsLoaded) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _thumbnailsLoaded = true);
                  });
                },
                // setState here keeps the readout live while dragging, which
                // is the point of showing it at all.
                onChangeStart: _config.attachCallbacks
                    ? (value) {
                        if (!mounted || value == _startValue) return;
                        setState(() => _startValue = value);
                      }
                    : null,
                onChangeEnd: _config.attachCallbacks
                    ? (value) {
                        if (!mounted || value == _endValue) return;
                        setState(() => _endValue = value);
                      }
                    : null,
                onChangePlaybackState: _config.attachCallbacks
                    ? (value) {
                        if (mounted) setState(() => _isPlaying = value);
                      }
                    : null,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  key: const Key('loop_toggle'),
                  tooltip: _looping ? 'Looping' : 'Not looping',
                  color: _looping ? Colors.tealAccent : Colors.white54,
                  icon: Icon(_looping ? Icons.repeat_on : Icons.repeat),
                  onPressed: () async {
                    await _trimmer.videoPlayerController?.setLooping(!_looping);
                    if (mounted) setState(() => _looping = !_looping);
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  key: const Key('play_pause'),
                  iconSize: 64,
                  color: Colors.white,
                  icon: Icon(_isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill),
                  onPressed: () async {
                    final playing = await _trimmer.videoPlaybackControl(
                      startValue: _startValue,
                      endValue: _endValue,
                    );
                    if (mounted) setState(() => _isPlaying = playing);
                  },
                ),
                const SizedBox(width: 16),
                TextButton(
                  key: const Key('speed_toggle'),
                  onPressed: () async {
                    final next =
                        _speeds[(_speeds.indexOf(_speed) + 1) % _speeds.length];
                    await _trimmer.videoPlayerController
                        ?.setPlaybackSpeed(next);
                    if (mounted) setState(() => _speed = next);
                  },
                  child: Text('${_speed}x',
                      style: const TextStyle(color: Colors.white70)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Shows the live trim range, which is the quickest way to tell whether
/// dragging and scrolling are reporting sane values.
class _SelectionReadout extends StatelessWidget {
  const _SelectionReadout({
    required this.startMs,
    required this.endMs,
    required this.thumbnailsLoaded,
  });

  final double startMs;
  final double endMs;
  final bool thumbnailsLoaded;

  static String _fmt(double ms) =>
      '${(ms / 1000).toStringAsFixed(2).padLeft(6)}s';

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: Colors.white70,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('start ${_fmt(startMs)}', style: style),
          Text('length ${_fmt(endMs - startMs)}',
              style: style.copyWith(color: const Color(0xFFF9A825))),
          Text('end ${_fmt(endMs)}', style: style),
          Icon(
            thumbnailsLoaded
                ? Icons.check_circle_outline
                : Icons.more_horiz_rounded,
            size: 16,
            color: thumbnailsLoaded ? Colors.tealAccent : Colors.white24,
          ),
        ],
      ),
    );
  }
}

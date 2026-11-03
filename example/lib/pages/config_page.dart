import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

import '../models/trimmer_config.dart';
import '../widgets/control_tiles.dart';

/// The playground: every option the package exposes, live-editable, so a
/// combination can be tried without touching code.
class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key, required this.config});

  final TrimmerConfig config;

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  late TrimmerConfig _config = widget.config;

  void _update(TrimmerConfig next) => setState(() => _config = next);

  static String _durationStyleLabel(DurationStyle style) =>
      style.name.replaceFirst('FORMAT_', '').replaceAll('_', ':');

  static String _boxFitLabel(BoxFit fit) => fit.name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customization'),
        actions: [
          TextButton(
            onPressed: () => _update(const TrimmerConfig()),
            child: const Text('RESET'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          // ------------------------------ Viewer ------------------------------
          ControlSection(
            title: 'Trim viewer',
            subtitle: 'TrimViewer — which viewer runs, and how big it is.',
            children: [
              ChoiceTile<ViewerType>(
                label: 'type',
                value: _config.viewerType,
                options: ViewerType.values,
                labelBuilder: (v) => v.name,
                onChanged: (v) => _update(_config.copyWith(viewerType: v)),
              ),
              SliderTile(
                label: 'maxVideoLength',
                value: _config.maxVideoLengthSeconds.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                decimals: 0,
                suffix: 's',
                onChanged: (v) =>
                    _update(_config.copyWith(maxVideoLengthSeconds: v.round())),
              ),
              SliderTile(
                label: 'minVideoLength',
                value: _config.minVideoLengthSeconds.toDouble(),
                min: 0,
                max: 30,
                divisions: 30,
                decimals: 0,
                suffix: 's',
                onChanged: (v) =>
                    _update(_config.copyWith(minVideoLengthSeconds: v.round())),
              ),
              SliderTile(
                label: 'viewerHeight',
                value: _config.viewerHeight,
                min: 30,
                max: 120,
                divisions: 18,
                decimals: 0,
                onChanged: (v) => _update(_config.copyWith(viewerHeight: v)),
              ),
              SliderTile(
                label: 'paddingFraction',
                value: _config.paddingFraction,
                min: 0.0,
                max: 0.5,
                divisions: 10,
                decimals: 2,
                onChanged: (v) => _update(_config.copyWith(paddingFraction: v)),
              ),
              SwitchTile(
                label: 'attach callbacks',
                subtitle:
                    'Off builds TrimViewer with onChangeStart/End/PlaybackState '
                    'omitted — the case that used to throw.',
                value: _config.attachCallbacks,
                onChanged: (v) => _update(_config.copyWith(attachCallbacks: v)),
              ),
            ],
          ),

          // ----------------------------- Duration -----------------------------
          ControlSection(
            title: 'Duration labels',
            children: [
              SwitchTile(
                label: 'showDuration',
                value: _config.showDuration,
                onChanged: (v) => _update(_config.copyWith(showDuration: v)),
              ),
              ChoiceTile<DurationStyle>(
                label: 'durationStyle',
                value: _config.durationStyle,
                options: DurationStyle.values,
                labelBuilder: _durationStyleLabel,
                onChanged: (v) => _update(_config.copyWith(durationStyle: v)),
              ),
              ColorTile(
                label: 'text color',
                value: _config.durationTextColor,
                onChanged: (v) =>
                    _update(_config.copyWith(durationTextColor: v)),
              ),
              SliderTile(
                label: 'font size',
                value: _config.durationFontSize,
                min: 9,
                max: 24,
                divisions: 15,
                decimals: 0,
                onChanged: (v) =>
                    _update(_config.copyWith(durationFontSize: v)),
              ),
              SwitchTile(
                label: 'bold',
                value: _config.durationBold,
                onChanged: (v) => _update(_config.copyWith(durationBold: v)),
              ),
            ],
          ),

          // --------------------------- Trim editor ----------------------------
          ControlSection(
            title: 'Trim editor',
            subtitle: 'TrimEditorProperties — the frame and its handles.',
            children: [
              ColorTile(
                label: 'borderPaintColor',
                value: _config.borderPaintColor,
                onChanged: (v) =>
                    _update(_config.copyWith(borderPaintColor: v)),
              ),
              ChoiceTile<TrimHandleStyle>(
                label: 'handleStyle',
                value: _config.handleStyle,
                options: TrimHandleStyle.values,
                labelBuilder: (v) => v.name,
                onChanged: (v) => _update(_config.copyWith(handleStyle: v)),
              ),
              if (_config.handleStyle == TrimHandleStyle.line) ...[
                ChoiceTile<bool>(
                  label: 'handleHeight',
                  value: _config.handleHeightInPixels,
                  options: const [false, true],
                  labelBuilder: (v) => v ? '.pixels' : '.percent',
                  onChanged: (v) =>
                      _update(_config.copyWith(handleHeightInPixels: v)),
                ),
                SliderTile(
                  label: _config.handleHeightInPixels
                      ? 'handleHeight (px)'
                      : 'handleHeight (%)',
                  value: _config.handleHeightValue,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (v) =>
                      _update(_config.copyWith(handleHeightValue: v)),
                ),
              ],
              ColorTile(
                label: 'circlePaintColor',
                value: _config.circlePaintColor,
                onChanged: (v) =>
                    _update(_config.copyWith(circlePaintColor: v)),
              ),
              ColorTile(
                label: 'scrubberPaintColor',
                value: _config.scrubberPaintColor,
                onChanged: (v) =>
                    _update(_config.copyWith(scrubberPaintColor: v)),
              ),
              SliderTile(
                label: 'borderWidth',
                value: _config.borderWidth,
                min: 0,
                max: 10,
                divisions: 20,
                onChanged: (v) => _update(_config.copyWith(borderWidth: v)),
              ),
              SliderTile(
                label: 'borderRadius',
                value: _config.editorBorderRadius,
                min: 0,
                max: 20,
                divisions: 20,
                onChanged: (v) =>
                    _update(_config.copyWith(editorBorderRadius: v)),
              ),
              SliderTile(
                label: 'circleSize',
                value: _config.circleSize,
                min: 0,
                max: 16,
                divisions: 32,
                onChanged: (v) => _update(_config.copyWith(circleSize: v)),
              ),
              SliderTile(
                label: 'circleSizeOnDrag',
                value: _config.circleSizeOnDrag,
                min: 0,
                max: 24,
                divisions: 24,
                onChanged: (v) =>
                    _update(_config.copyWith(circleSizeOnDrag: v)),
              ),
              SliderTile(
                label: 'scrubberWidth',
                value: _config.scrubberWidth,
                min: 0,
                max: 8,
                divisions: 16,
                onChanged: (v) => _update(_config.copyWith(scrubberWidth: v)),
              ),
              SliderTile(
                label: 'sideTapSize',
                value: _config.sideTapSize.toDouble(),
                min: 4,
                max: 64,
                divisions: 15,
                decimals: 0,
                suffix: 'px',
                onChanged: (v) =>
                    _update(_config.copyWith(sideTapSize: v.round())),
              ),
            ],
          ),

          // ---------------------------- Trim area -----------------------------
          ControlSection(
            title: 'Trim area',
            subtitle:
                'TrimAreaProperties — the thumbnail strip behind the frame.',
            children: [
              ChoiceTile<AreaPropertiesStyle>(
                label: 'constructor',
                value: _config.areaStyle,
                options: AreaPropertiesStyle.values,
                labelBuilder: (v) => v.label,
                onChanged: (v) => _update(_config.copyWith(areaStyle: v)),
              ),
              ChoiceTile<BoxFit>(
                label: 'thumbnailFit',
                value: _config.thumbnailFit,
                options: const [
                  BoxFit.fitHeight,
                  BoxFit.fitWidth,
                  BoxFit.cover,
                  BoxFit.contain,
                  BoxFit.fill,
                ],
                labelBuilder: _boxFitLabel,
                onChanged: (v) => _update(_config.copyWith(thumbnailFit: v)),
              ),
              SliderTile(
                label: 'thumbnailQuality',
                value: _config.thumbnailQuality.toDouble(),
                min: 10,
                max: 100,
                divisions: 18,
                decimals: 0,
                onChanged: (v) =>
                    _update(_config.copyWith(thumbnailQuality: v.round())),
              ),
              SliderTile(
                label: 'borderRadius',
                value: _config.areaBorderRadius,
                min: 0,
                max: 24,
                divisions: 24,
                onChanged: (v) =>
                    _update(_config.copyWith(areaBorderRadius: v)),
              ),
              if (_config.areaStyle != AreaPropertiesStyle.fixed) ...[
                SwitchTile(
                  label: 'blurEdges',
                  value: _config.blurEdges,
                  onChanged: (v) => _update(_config.copyWith(blurEdges: v)),
                ),
                ColorTile(
                  label: 'blurColor',
                  value: _config.blurColor,
                  onChanged: (v) => _update(_config.copyWith(blurColor: v)),
                ),
                ChoiceTile<EdgeIconStyle>(
                  label: 'startIcon / endIcon',
                  value: _config.edgeIconStyle,
                  options: EdgeIconStyle.values,
                  labelBuilder: (v) => v.label,
                  onChanged: (v) => _update(_config.copyWith(edgeIconStyle: v)),
                ),
              ],
            ],
          ),

          // ---------------------------- Scrolling -----------------------------
          ControlSection(
            title: 'Scrolling',
            subtitle: 'Only applies when the scrollable viewer is running.',
            children: [
              SwitchTile(
                label: 'allowManualScroll',
                subtitle: 'Drag the strip itself, not just the handles.',
                value: _config.allowManualScroll,
                onChanged: (v) =>
                    _update(_config.copyWith(allowManualScroll: v)),
              ),
              SliderTile(
                label: 'autoScrollEdgeZone',
                value: _config.autoScrollEdgeZone,
                min: 8,
                max: 120,
                divisions: 28,
                decimals: 0,
                suffix: 'px',
                onChanged: (v) =>
                    _update(_config.copyWith(autoScrollEdgeZone: v)),
              ),
              SliderTile(
                label: 'maxAutoScrollVelocity',
                value: _config.maxAutoScrollVelocity,
                min: 100,
                max: 2000,
                divisions: 38,
                decimals: 0,
                suffix: 'px/s',
                onChanged: (v) =>
                    _update(_config.copyWith(maxAutoScrollVelocity: v)),
              ),
              SliderTile(
                label: 'autoScrollStartDelay',
                value: _config.autoScrollStartDelayMs.toDouble(),
                min: 0,
                max: 1000,
                divisions: 20,
                decimals: 0,
                suffix: 'ms',
                onChanged: (v) => _update(
                    _config.copyWith(autoScrollStartDelayMs: v.round())),
              ),
            ],
          ),

          // --------------------------- Video viewer ---------------------------
          ControlSection(
            title: 'Video viewer',
            subtitle: 'VideoViewer — the playback area above the strip.',
            children: [
              ColorTile(
                label: 'borderColor',
                value: _config.videoBorderColor,
                includeTransparent: true,
                onChanged: (v) =>
                    _update(_config.copyWith(videoBorderColor: v)),
              ),
              SliderTile(
                label: 'borderWidth',
                value: _config.videoBorderWidth,
                min: 0,
                max: 12,
                divisions: 24,
                onChanged: (v) =>
                    _update(_config.copyWith(videoBorderWidth: v)),
              ),
              SliderTile(
                label: 'padding',
                value: _config.videoPadding,
                min: 0,
                max: 40,
                divisions: 20,
                decimals: 0,
                onChanged: (v) => _update(_config.copyWith(videoPadding: v)),
              ),
            ],
          ),

          // ------------------------------ Output ------------------------------
          ControlSection(
            title: 'Output',
            subtitle: 'Trimmer.saveTrimmedVideo — what gets written to disk.',
            children: [
              ChoiceTile<OutputType>(
                label: 'outputType',
                value: _config.outputType,
                options: OutputType.values,
                labelBuilder: (v) => v.name,
                onChanged: (v) => _update(_config.copyWith(outputType: v)),
              ),
              ChoiceTile<int>(
                label: 'storageDir',
                value: _config.storageDirIndex,
                options: const [0, 1, 2],
                labelBuilder: (i) => StorageDir.values[i].toString(),
                onChanged: (v) => _update(_config.copyWith(storageDirIndex: v)),
              ),
              TextTile(
                label: 'videoFolderName',
                value: _config.videoFolderName,
                hintText: 'Trimmer',
                onChanged: (v) => _update(_config.copyWith(videoFolderName: v)),
              ),
              TextTile(
                label: 'videoFileName',
                value: _config.customFileName,
                hintText: 'auto-generated',
                onChanged: (v) => _update(_config.copyWith(customFileName: v)),
              ),
              if (_config.outputType == OutputType.gif) ...[
                SliderTile(
                  label: 'fpsGIF',
                  value: _config.fpsGIF.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  decimals: 0,
                  onChanged: (v) =>
                      _update(_config.copyWith(fpsGIF: v.round())),
                ),
                SliderTile(
                  label: 'scaleGIF',
                  value: _config.scaleGIF.toDouble(),
                  min: 120,
                  max: 960,
                  divisions: 14,
                  decimals: 0,
                  suffix: 'px',
                  onChanged: (v) =>
                      _update(_config.copyWith(scaleGIF: v.round())),
                ),
                SliderTile(
                  label: 'qualityGIF',
                  value: _config.qualityGIF.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 18,
                  decimals: 0,
                  onChanged: (v) =>
                      _update(_config.copyWith(qualityGIF: v.round())),
                ),
              ],
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(_config),
        icon: const Icon(Icons.check),
        label: const Text('APPLY'),
      ),
    );
  }
}

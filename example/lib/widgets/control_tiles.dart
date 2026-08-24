import 'package:flutter/material.dart';

/// A titled group of controls.
class ControlSection extends StatelessWidget {
  const ControlSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFFF9A825),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ],
          ),
        ),
        ...children,
        const Divider(height: 24, color: Colors.white12),
      ],
    );
  }
}

/// A labelled slider that shows its current value.
class SliderTile extends StatelessWidget {
  const SliderTile({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.suffix = '',
    this.decimals = 1,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String suffix;
  final int decimals;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 5,
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '${value.toStringAsFixed(decimals)}$suffix',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontFeatures: [FontFeature.tabularFigures()],
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled switch.
class SwitchTile extends StatelessWidget {
  const SwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!,
              style: const TextStyle(fontSize: 11, color: Colors.white38)),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

/// A labelled row of choice chips, for enums small enough to show inline.
class ChoiceTile<T> extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              return ChoiceChip(
                label: Text(labelBuilder(option),
                    style: const TextStyle(fontSize: 12)),
                selected: option == value,
                onSelected: (_) => onChanged(option),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// A labelled row of colour swatches.
class ColorTile extends StatelessWidget {
  const ColorTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.includeTransparent = false,
  });

  final String label;
  final Color value;
  final ValueChanged<Color> onChanged;
  final bool includeTransparent;

  static const _palette = <Color>[
    Colors.white,
    Colors.yellow,
    Color(0xFFF9A825),
    Colors.redAccent,
    Colors.tealAccent,
    Colors.lightBlueAccent,
    Colors.purpleAccent,
    Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = [
      if (includeTransparent) Colors.transparent,
      ..._palette,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Wrap(
            spacing: 8,
            children: palette.map((color) {
              final selected = color.toARGB32() == value.toARGB32();
              return GestureDetector(
                onTap: () => onChanged(color),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          selected ? const Color(0xFFF9A825) : Colors.white24,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: color == Colors.transparent
                      ? const Icon(Icons.block, size: 14, color: Colors.white38)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// A labelled single-line text field.
class TextTile extends StatelessWidget {
  const TextTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hintText,
  });

  final String label;
  final String value;
  final String? hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(label, style: const TextStyle(fontSize: 14))),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: value,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 12, color: Colors.white24),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

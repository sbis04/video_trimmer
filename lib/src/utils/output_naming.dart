import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

/// Characters that are safe in a file name on every platform this package
/// targets, and that downstream media tooling reliably accepts.
final RegExp _unsafeFileNameChars = RegExp(r'[^A-Za-z0-9._-]');

/// Formats [time] as `yyyyMMdd_HHmmss` for generated file names.
///
/// Deliberately not a localized format: `DateFormat.yMMMd().add_Hms()` used to
/// produce names like `clip_trimmed:Apr28,2023-09:45:54.mp4`, and the colons
/// and commas broke `MediaMetadataRetriever` and several transcoders. Built by
/// hand so the package does not depend on `intl`, whose version the Flutter
/// SDK pins through `flutter_localizations`.
String formatFileTimestamp(DateTime time) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${time.year.toString().padLeft(4, '0')}${two(time.month)}'
      '${two(time.day)}_${two(time.hour)}${two(time.minute)}'
      '${two(time.second)}';
}

/// Replaces anything outside `[A-Za-z0-9._-]` with an underscore, collapses
/// runs of underscores, and trims leading and trailing separators.
///
/// Returns `untitled` if nothing usable is left.
String sanitizeFileName(String name) {
  final replaced = name.replaceAll(_unsafeFileNameChars, '_');
  final collapsed = replaced.replaceAll(RegExp(r'_+'), '_');
  final trimmed = collapsed.replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');
  return trimmed.isEmpty ? 'untitled' : trimmed;
}

/// The file extension (with the dot) for a trimmed video of [sourcePath].
///
/// Matches the container the native exporter actually writes: Media3 on
/// Android always produces MP4, and AVFoundation on Apple platforms keeps a
/// QuickTime source as `.mov` and writes MP4 otherwise. Naming the output
/// after the source used to put MP4 data in, say, a `.webm` file.
String trimmedVideoExtension(String sourcePath, TargetPlatform platform) {
  final ext = extension(sourcePath).toLowerCase();
  final apple =
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  if (apple && (ext == '.mov' || ext == '.m4v')) return ext;
  return '.mp4';
}

/// Builds the output file name (without extension) for a trim of [sourcePath].
///
/// [customName] wins when given, sanitized. Otherwise the name is the source
/// file's own base name plus `_trimmed_` and a filesystem-safe [timestamp].
String buildOutputFileName({
  required String sourcePath,
  required DateTime timestamp,
  String? customName,
}) {
  if (customName != null && customName.trim().isNotEmpty) {
    return sanitizeFileName(customName);
  }
  // basenameWithoutExtension, not split('.').first: the old code truncated any
  // name containing a dot, so `my.clip.mp4` became `my`.
  final base = sanitizeFileName(basenameWithoutExtension(sourcePath));
  return '${base}_trimmed_${formatFileTimestamp(timestamp)}';
}

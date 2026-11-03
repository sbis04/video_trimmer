import 'package:intl/intl.dart';
import 'package:path/path.dart';

/// Characters that are safe in a file name on every platform this package
/// targets, and that downstream media tooling reliably accepts.
final RegExp _unsafeFileNameChars = RegExp(r'[^A-Za-z0-9._-]');

/// Timestamp format for generated file names.
///
/// Deliberately not a localized format: `DateFormat.yMMMd().add_Hms()` used to
/// produce names like `clip_trimmed:Apr28,2023-09:45:54.mp4`, and the colons
/// and commas broke `MediaMetadataRetriever` and several transcoders.
final DateFormat _stampFormat = DateFormat('yyyyMMdd_HHmmss');

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
  return '${base}_trimmed_${_stampFormat.format(timestamp)}';
}

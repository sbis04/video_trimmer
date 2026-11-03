import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Extracts JPEG frames from a local video file through the package's own
/// native code (AVAssetImageGenerator on iOS, MediaMetadataRetriever on
/// Android).
///
/// This replaces `get_thumbnail_video`, whose iOS plugin class shares its name
/// with `video_thumbnail` and crashed apps that depended on both.
class ThumbnailGenerator {
  ThumbnailGenerator._();

  @visibleForTesting
  static const MethodChannel channel =
      MethodChannel('video_trimmer/thumbnails');

  /// Returns a JPEG of the frame at [timeMs] in [videoPath], scaled down to fit
  /// inside [maxWidth] x [maxHeight] while keeping its aspect ratio. Leave a
  /// bound null to leave that side unconstrained.
  static Future<Uint8List> thumbnailData({
    required String videoPath,
    required int timeMs,
    int? maxWidth,
    int? maxHeight,
    int quality = 75,
  }) async {
    final bytes = await channel.invokeMethod<Uint8List>('thumbnail', {
      'path': videoPath,
      'timeMs': timeMs < 0 ? 0 : timeMs,
      'maxWidth': maxWidth ?? 0,
      'maxHeight': maxHeight ?? 0,
      'quality': quality.clamp(0, 100),
    });
    if (bytes == null) {
      throw PlatformException(
        code: 'thumbnail_failed',
        message: 'No frame at $timeMs ms',
        details: videoPath,
      );
    }
    return bytes;
  }

  /// Frees the native decoder kept open for the last video.
  static Future<void> release() async {
    try {
      await channel.invokeMethod<void>('release');
    } on MissingPluginException {
      // Not registered (for example in a pure-Dart test); nothing to free.
    }
  }
}

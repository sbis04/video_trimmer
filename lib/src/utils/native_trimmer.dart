import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Cuts a video through the package's own native code: AVAssetExportSession
/// on iOS and Media3 Transformer on Android.
///
/// This replaces `flutter_native_video_trimmer`, whose generic plugin names
/// (`VideoTrimmerPlugin`, `com.example.video_trimmer`) risked the same launch
/// crash `video_thumbnail` caused, and which had no Swift Package Manager
/// support.
class NativeTrimmer {
  NativeTrimmer._();

  @visibleForTesting
  static const MethodChannel channel = MethodChannel('video_trimmer/trim');

  /// Writes [startMs, endMs) of [inputPath] to [outputPath] and returns
  /// [outputPath]. Throws a [PlatformException] if the export fails.
  static Future<String> trim({
    required String inputPath,
    required String outputPath,
    required int startMs,
    required int endMs,
  }) async {
    if (endMs <= startMs) {
      throw ArgumentError.value(
          endMs, 'endMs', 'must be greater than startMs ($startMs)');
    }
    final path = await channel.invokeMethod<String>('trim', {
      'path': inputPath,
      'outputPath': outputPath,
      'startMs': startMs < 0 ? 0 : startMs,
      'endMs': endMs,
    });
    if (path == null) {
      throw PlatformException(
        code: 'trim_failed',
        message: 'The native trimmer returned no output.',
        details: inputPath,
      );
    }
    return path;
  }
}

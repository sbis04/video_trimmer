import 'dart:typed_data';

import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/utils/storage_dir.dart';

Never _unsupported() =>
    throw UnsupportedError('video_trimmer is not supported on this platform.');

/// Throws if [path] cannot be read as a video source.
Future<void> ensureVideoExists(String path) async => _unsupported();

/// A player for the video at [path].
VideoPlayerController createVideoController(String path) => _unsupported();

/// The folder trimmed files go into, created if needed.
Future<String> prepareOutputFolder(String folderName, StorageDir storageDir) =>
    _unsupported();

/// Saves [bytes] as the output at [outputPath] and returns where it ended up.
Future<String> writeOutputBytes(
        Uint8List bytes, String outputPath, String mimeType) =>
    _unsupported();

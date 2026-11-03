import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/utils/storage_dir.dart';

Never _unsupported() =>
    throw UnsupportedError('video_trimmer is not supported on this platform.');

/// Throws if [file] cannot be read as a video source.
Future<void> ensureVideoExists(XFile file) async => _unsupported();

/// A player for [file].
VideoPlayerController createVideoController(XFile file) => _unsupported();

/// The folder trimmed files go into, created if needed.
Future<String> prepareOutputFolder(String folderName, StorageDir storageDir) =>
    _unsupported();

/// Saves [bytes] as the output at [outputPath] and returns where it ended up.
Future<String> writeOutputBytes(
        Uint8List bytes, String outputPath, String mimeType) =>
    _unsupported();

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/utils/storage_dir.dart';

/// Throws a [FileSystemException] if there is no file at [path].
Future<void> ensureVideoExists(String path) async {
  if (!await File(path).exists()) {
    throw FileSystemException('Video file not found', path);
  }
}

VideoPlayerController createVideoController(String path) =>
    VideoPlayerController.file(File(path));

Future<String> prepareOutputFolder(
    String folderName, StorageDir storageDir) async {
  // Exhaustive switch on a real enum. This used to dispatch on
  // `storageDir.toString()` with no default arm, so an unmatched value left
  // the directory null and the next line dereferenced it.
  final Directory? directory = switch (storageDir) {
    StorageDir.temporaryDirectory => await getTemporaryDirectory(),
    StorageDir.applicationDocumentsDirectory =>
      await getApplicationDocumentsDirectory(),
    // Returns null on every platform except Android.
    StorageDir.externalStorageDirectory => await getExternalStorageDirectory(),
  };
  if (directory == null) {
    throw UnsupportedError(
      'StorageDir.externalStorageDirectory is not available on this '
      'platform. Use temporaryDirectory or applicationDocumentsDirectory.',
    );
  }
  final folder = Directory(join(directory.path, folderName));
  await folder.create(recursive: true);
  return folder.path;
}

Future<String> writeOutputBytes(
    Uint8List bytes, String outputPath, String mimeType) async {
  await File(outputPath).writeAsBytes(bytes, flush: true);
  return outputPath;
}

import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/utils/storage_dir.dart';

/// Throws a [FileSystemException] if [file] does not exist.
Future<void> ensureVideoExists(XFile file) async {
  if (!await File(file.path).exists()) {
    throw FileSystemException('Video file not found', file.path);
  }
}

VideoPlayerController createVideoController(XFile file) =>
    VideoPlayerController.file(File(file.path));

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

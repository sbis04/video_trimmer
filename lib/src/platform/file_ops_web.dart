import 'dart:js_interop';
import 'dart:typed_data';

import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/utils/storage_dir.dart';
import 'package:web/web.dart' as web;

/// Browsers hand out files as blob: URLs that are readable by construction.
Future<void> ensureVideoExists(String path) async {}

VideoPlayerController createVideoController(String path) =>
    VideoPlayerController.networkUrl(Uri.parse(path));

/// There is no file system on the web; outputs become blob: URLs, so the
/// folder only ever prefixes a name nobody sees.
Future<String> prepareOutputFolder(
        String folderName, StorageDir storageDir) async =>
    '';

/// Returns a blob: URL for [bytes]. Read it back with `fetch` (or
/// `XFile(url)`), play it with `VideoPlayerController.networkUrl`, or offer it
/// as a download.
Future<String> writeOutputBytes(
    Uint8List bytes, String outputPath, String mimeType) async {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  return web.URL.createObjectURL(blob);
}

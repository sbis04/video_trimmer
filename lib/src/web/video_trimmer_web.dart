import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'mediabunny_source.dart';

/// The package's web side. It answers the same method channels as the native
/// plugins, so the rest of the package runs unchanged in the browser:
///
/// * `video_trimmer/thumbnails`: frames are drawn from a hidden `<video>`
///   element onto a canvas and encoded as JPEG.
/// * `video_trimmer/trim`: the range is cut with Mediabunny (WebCodecs) into
///   an MP4, returned as a blob: URL.
class VideoTrimmerWeb {
  VideoTrimmerWeb._();

  static void registerWith(Registrar registrar) {
    final instance = VideoTrimmerWeb._();
    MethodChannel(
            'video_trimmer/thumbnails', const StandardMethodCodec(), registrar)
        .setMethodCallHandler(instance._handleThumbnails);
    MethodChannel('video_trimmer/trim', const StandardMethodCodec(), registrar)
        .setMethodCallHandler(instance._handleTrim);
  }

  // ---- Thumbnails ----------------------------------------------------------

  // One element is reused for every frame of the same video, like the native
  // decoders; requests are serialized because it can only seek one way at a
  // time.
  web.HTMLVideoElement? _video;
  String? _videoUrl;
  Future<void> _queue = Future<void>.value();

  Future<Object?> _handleThumbnails(MethodCall call) async {
    switch (call.method) {
      case 'thumbnail':
        final args = (call.arguments as Map).cast<String, Object?>();
        final path = args['path'] as String?;
        if (path == null) {
          throw PlatformException(
              code: 'bad_args', message: 'path is required');
        }
        return _serial(() => _frame(
              path,
              (args['timeMs'] as num? ?? 0).toInt(),
              (args['maxWidth'] as num? ?? 0).toInt(),
              (args['maxHeight'] as num? ?? 0).toInt(),
              (args['quality'] as num? ?? 75).toInt(),
            ));
      case 'release':
        _releaseVideo();
        return null;
    }
    throw MissingPluginException(call.method);
  }

  Future<T> _serial<T>(Future<T> Function() task) {
    final next = _queue.then((_) => task());
    _queue = next.then((_) {}, onError: (Object _) {});
    return next;
  }

  Future<Uint8List> _frame(
      String url, int timeMs, int maxWidth, int maxHeight, int quality) async {
    try {
      final video = await _open(url);
      final duration = video.duration;
      var seconds = timeMs / 1000;
      // Seeking exactly to the end shows nothing in some browsers.
      if (duration.isFinite && seconds > duration - 0.001) {
        seconds = duration - 0.001 < 0 ? 0 : duration - 0.001;
      }
      await _seek(video, seconds);

      final w = video.videoWidth, h = video.videoHeight;
      if (w == 0 || h == 0) throw StateError('The video has no picture.');
      var scale = 1.0;
      if (maxWidth > 0 && w > maxWidth) scale = maxWidth / w;
      if (maxHeight > 0 && h * scale > maxHeight) scale = maxHeight / h;
      final dw = (w * scale).round().clamp(1, w);
      final dh = (h * scale).round().clamp(1, h);

      final canvas = web.HTMLCanvasElement()
        ..width = dw
        ..height = dh;
      final context = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
      context.drawImage(video, 0, 0, dw, dh);
      final blob = await _toBlob(canvas, quality.clamp(0, 100) / 100);
      final buffer = await blob.arrayBuffer().toDart;
      return buffer.toDart.asUint8List();
    } on PlatformException {
      rethrow;
    } catch (e) {
      throw PlatformException(
          code: 'thumbnail_failed', message: '$e', details: url);
    }
  }

  Future<web.HTMLVideoElement> _open(String url) async {
    final cached = _video;
    if (cached != null && _videoUrl == url) return cached;
    _releaseVideo();
    final video = web.HTMLVideoElement()
      ..muted = true
      ..preload = 'auto'
      ..crossOrigin = 'anonymous'
      ..src = url;
    _video = video;
    _videoUrl = url;
    await _once(video, 'loadeddata');
    return video;
  }

  void _releaseVideo() {
    final video = _video;
    _video = null;
    _videoUrl = null;
    if (video != null) {
      video.removeAttribute('src');
      video.load();
    }
  }

  static Future<void> _seek(web.HTMLVideoElement video, double seconds) async {
    if ((video.currentTime - seconds).abs() < 0.0005 && video.readyState >= 2) {
      return;
    }
    final seeked = _once(video, 'seeked');
    video.currentTime = seconds;
    await seeked;
  }

  /// Completes on the first [event] from [target], or fails on its `error`.
  static Future<void> _once(web.EventTarget target, String event) {
    final completer = Completer<void>();
    late final JSFunction onEvent;
    late final JSFunction onError;
    void done() {
      target.removeEventListener(event, onEvent);
      target.removeEventListener('error', onError);
    }

    onEvent = ((web.Event _) {
      done();
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    onError = ((web.Event _) {
      done();
      if (!completer.isCompleted) {
        completer.completeError(StateError('The browser could not decode the '
            'video (waiting for "$event").'));
      }
    }).toJS;
    target.addEventListener(event, onEvent);
    target.addEventListener('error', onError);
    return completer.future;
  }

  static Future<web.Blob> _toBlob(
      web.HTMLCanvasElement canvas, double quality) {
    final completer = Completer<web.Blob>();
    canvas.toBlob(
      ((web.Blob? blob) {
        if (blob == null) {
          completer.completeError(StateError('JPEG encoding failed.'));
        } else {
          completer.complete(blob);
        }
      }).toJS,
      'image/jpeg',
      quality.toJS,
    );
    return completer.future;
  }

  // ---- Trimming ------------------------------------------------------------

  static Future<void>? _mediabunnyLoad;

  Future<Object?> _handleTrim(MethodCall call) async {
    if (call.method != 'trim') throw MissingPluginException(call.method);
    final args = (call.arguments as Map).cast<String, Object?>();
    final path = args['path'] as String?;
    final startMs = args['startMs'] as num?;
    final endMs = args['endMs'] as num?;
    if (path == null || startMs == null || endMs == null) {
      throw PlatformException(
          code: 'bad_args', message: 'path, startMs and endMs are required');
    }
    try {
      await (_mediabunnyLoad ??= _loadMediabunny());
      final response = await web.window.fetch(path.toJS).toDart;
      final source = await response.blob().toDart;
      final trimmed =
          await _trim(source, (startMs / 1000).toJS, (endMs / 1000).toJS)
              .toDart;
      return web.URL.createObjectURL(trimmed);
    } catch (e) {
      throw PlatformException(
          code: 'trim_failed', message: '$e', details: path);
    }
  }

  /// Loads the embedded Mediabunny module plus a small glue module that puts
  /// one `trim` function on `globalThis`. A `<script type="module">` is used
  /// rather than `importModule`, whose Dart signature differs between the SDK
  /// versions this package supports.
  static Future<void> _loadMediabunny() async {
    String blobUrl(String source) => web.URL.createObjectURL(web.Blob(
          <JSAny>[source.toJS].toJS,
          web.BlobPropertyBag(type: 'text/javascript'),
        ));
    final library = blobUrl(mediabunnySource);
    final glue = blobUrl('''
import * as mb from '$library';
globalThis.$_trimFunction = async (blob, start, end) => {
  const input = new mb.Input({ formats: mb.ALL_FORMATS, source: new mb.BlobSource(blob) });
  const output = new mb.Output({ format: new mb.Mp4OutputFormat(), target: new mb.BufferTarget() });
  const conversion = await mb.Conversion.init({ input, output, trim: { start, end } });
  if (!conversion.isValid) {
    const reasons = conversion.discardedTracks.map((t) => t.reason).join(', ');
    throw new Error('This browser cannot trim this video (' + reasons + ').');
  }
  await conversion.execute();
  return new Blob([output.target.buffer], { type: 'video/mp4' });
};
''');
    final script = web.HTMLScriptElement()
      ..type = 'module'
      ..src = glue;
    final loaded = _once(script, 'load');
    web.document.head!.append(script);
    try {
      await loaded;
    } catch (_) {
      _mediabunnyLoad = null; // let a later call retry
      rethrow;
    }
  }

  static const String _trimFunction = '__videoTrimmerTrim';
}

@JS(VideoTrimmerWeb._trimFunction)
external JSPromise<web.Blob> _trim(
    web.Blob source, JSNumber start, JSNumber end);

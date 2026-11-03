import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_trimmer/src/utils/thumbnail_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(ThumbnailGenerator.channel,
        (call) async {
      calls.add(call);
      if (call.method == 'thumbnail') {
        return (call.arguments as Map)['path'] == 'missing.mp4'
            ? null
            : Uint8List.fromList([0xFF, 0xD8, 0xFF]);
      }
      return null;
    });
  });

  tearDown(() =>
      messenger.setMockMethodCallHandler(ThumbnailGenerator.channel, null));

  test('sends normalized arguments and returns the bytes', () async {
    final bytes = await ThumbnailGenerator.thumbnailData(
      videoPath: '/v.mp4',
      timeMs: -5,
      maxHeight: 50,
      quality: 140,
    );
    expect(bytes, [0xFF, 0xD8, 0xFF]);
    expect(calls.single.method, 'thumbnail');
    expect(calls.single.arguments, {
      'path': '/v.mp4',
      'timeMs': 0,
      'maxWidth': 0,
      'maxHeight': 50,
      'quality': 100,
    });
  });

  test('a null reply surfaces as a PlatformException', () {
    expect(
      ThumbnailGenerator.thumbnailData(videoPath: 'missing.mp4', timeMs: 0),
      throwsA(isA<PlatformException>()),
    );
  });

  test('release tolerates a missing plugin', () async {
    messenger.setMockMethodCallHandler(ThumbnailGenerator.channel, null);
    await ThumbnailGenerator.release();
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_trimmer/src/utils/native_trimmer.dart';
import 'package:video_trimmer/src/utils/output_naming.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeTrimmer.trim', () {
    final calls = <MethodCall>[];
    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(NativeTrimmer.channel, (call) async {
        calls.add(call);
        return (call.arguments as Map)['outputPath'];
      });
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(NativeTrimmer.channel, null);
    });

    test('sends the paths and range and returns the output path', () async {
      final out = await NativeTrimmer.trim(
          inputPath: '/in.mp4',
          outputPath: '/out.mp4',
          startMs: 1200,
          endMs: 4800);
      expect(out, '/out.mp4');
      expect(calls.single.method, 'trim');
      expect(calls.single.arguments, {
        'path': '/in.mp4',
        'outputPath': '/out.mp4',
        'startMs': 1200,
        'endMs': 4800,
      });
    });

    test('clamps a negative start to 0', () async {
      await NativeTrimmer.trim(
          inputPath: '/in.mp4', outputPath: '/out.mp4', startMs: -5, endMs: 10);
      expect((calls.single.arguments as Map)['startMs'], 0);
    });

    test('rejects an empty range without calling native code', () async {
      expect(
        () => NativeTrimmer.trim(
            inputPath: '/in.mp4',
            outputPath: '/out.mp4',
            startMs: 10,
            endMs: 10),
        throwsArgumentError,
      );
      expect(calls, isEmpty);
    });

    test('surfaces native failures as PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(NativeTrimmer.channel, (call) async {
        throw PlatformException(code: 'trim_failed', message: 'boom');
      });
      expect(
        () => NativeTrimmer.trim(
            inputPath: '/in.mp4',
            outputPath: '/out.mp4',
            startMs: 0,
            endMs: 10),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('trimmedVideoExtension', () {
    test('Android always writes MP4', () {
      for (final src in ['a.mp4', 'a.mov', 'a.webm', 'a.MKV', 'noext']) {
        expect(trimmedVideoExtension(src, TargetPlatform.android), '.mp4');
      }
    });
    test('Apple platforms keep QuickTime sources', () {
      for (final p in [TargetPlatform.iOS, TargetPlatform.macOS]) {
        expect(trimmedVideoExtension('a.mov', p), '.mov');
        expect(trimmedVideoExtension('a.m4v', p), '.m4v');
        expect(trimmedVideoExtension('a.MOV', p), '.mov');
        expect(trimmedVideoExtension('a.mp4', p), '.mp4');
        expect(trimmedVideoExtension('a.webm', p), '.mp4');
      }
    });
  });
}

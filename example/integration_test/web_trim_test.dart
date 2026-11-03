// Web counterpart of trimmer_flow_test.dart, which needs dart:io. Run it in
// Chrome with test_driver/integration_test.dart (see that file).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<XFile> sample() async {
    final data = await rootBundle.load('assets/sample.mp4');
    return XFile.fromData(data.buffer.asUint8List(),
        mimeType: 'video/mp4', name: 'sample.mp4');
  }

  Future<void> pumpUntil(WidgetTester tester, bool Function() done,
      {Duration timeout = const Duration(seconds: 60),
      required String reason}) async {
    final deadline = DateTime.now().add(timeout);
    while (!done()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out waiting for $reason');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<Trimmer> loadedTrimmer(WidgetTester tester) async {
    final trimmer = Trimmer();
    addTearDown(trimmer.dispose);
    await trimmer.loadVideo(videoFile: await sample());
    expect(trimmer.videoPlayerController!.value.duration.inSeconds, 30);
    return trimmer;
  }

  Future<String?> save(WidgetTester tester, Trimmer trimmer,
      {OutputType type = OutputType.video}) async {
    String? saved;
    var done = false;
    await trimmer.saveTrimmedVideo(
      startValue: 2000,
      endValue: 5000,
      outputType: type,
      fpsGIF: 5,
      scaleGIF: 160,
      onSave: (path) {
        saved = path;
        done = true;
      },
    );
    await pumpUntil(tester, () => done,
        timeout: const Duration(seconds: 120), reason: 'the export');
    return saved;
  }

  testWidgets('the trim viewer shows JPEG frames drawn in the browser',
      (tester) async {
    final trimmer = await loadedTrimmer(tester);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: TrimViewer(
            trimmer: trimmer,
            viewerWidth: 360,
            viewerHeight: 50,
            maxVideoLength: const Duration(seconds: 10),
          ),
        ),
      ),
    ));

    Iterable<Uint8List> frames() => tester
        .widgetList<FadeInImage>(find.byType(FadeInImage))
        .map((w) => w.image)
        .whereType<MemoryImage>()
        .map((m) => m.bytes)
        .where((b) => b.length > 100);
    await pumpUntil(tester, () => frames().length >= 3,
        reason: 'thumbnails to render');
    for (final bytes in frames()) {
      expect(bytes.sublist(0, 3), [0xFF, 0xD8, 0xFF], reason: 'JPEG magic');
    }
  });

  testWidgets('Mediabunny trims exactly the selected range to an MP4',
      (tester) async {
    final trimmer = await loadedTrimmer(tester);
    final url = await save(tester, trimmer);

    expect(url, isNotNull, reason: 'onSave(null) means the export failed');
    expect(url, startsWith('blob:'));
    final bytes = await XFile(url!).readAsBytes();
    // An MP4 starts with an ftyp box.
    expect(String.fromCharCodes(bytes.sublist(4, 8)), 'ftyp');

    final check = VideoPlayerController.networkUrl(Uri.parse(url));
    addTearDown(check.dispose);
    await check.initialize();
    expect(check.value.duration.inMilliseconds, closeTo(3000, 150),
        reason: 'the output should be the 3 s that were selected');
  });

  testWidgets('a GIF can be saved in the browser', (tester) async {
    final trimmer = await loadedTrimmer(tester);
    final url = await save(tester, trimmer, type: OutputType.gif);

    expect(url, startsWith('blob:'));
    final bytes = await XFile(url!).readAsBytes();
    expect(String.fromCharCodes(bytes.sublist(0, 3)), 'GIF');
  });
}

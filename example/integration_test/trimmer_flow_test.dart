import 'dart:io';

import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
// The painter is not exported; the tests read the scrubber position off it.
// ignore: implementation_imports
import 'package:video_trimmer/src/trim_viewer/trim_editor_painter.dart';
import 'package:video_trimmer/video_trimmer.dart';

/// End-to-end coverage for the trimmer running against the bundled sample
/// clip: the viewer renders, handles drag, the strip scrolls both ways, and a
/// trim actually lands on disk.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps frames until [condition] holds, or fails after [timeout]. Used
  /// instead of `pumpAndSettle` because the video player and the thumbnail
  /// stream keep the tree busy indefinitely.
  Future<void> pumpUntil(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 30),
    String? reason,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out waiting for: ${reason ?? 'condition'}');
      }
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Reads one of the live values out of the trim readout, e.g. `end 12.34s`.
  double readout(String label) {
    final finder = find.textContaining(RegExp('^$label '));
    expect(finder, findsOneWidget, reason: 'no "$label" readout on screen');
    final text = (finder.evaluate().single.widget as Text).data!;
    final match = RegExp(r'([\d.]+)s').firstMatch(text);
    expect(match, isNotNull, reason: 'unparsable readout: "$text"');
    return double.parse(match!.group(1)!);
  }

  /// Boots the app and gets as far as a loaded trimmer with thumbnails.
  Future<void> openSampleTrimmer(WidgetTester tester) async {
    await tester.pumpWidget(const VideoTrimmerExample());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('use_sample')));
    await pumpUntil(
      tester,
      () => find.byType(TrimViewer).evaluate().isNotEmpty,
      reason: 'TrimViewer to mount',
    );

    // The strip only has a scrollable extent once thumbnails have been laid
    // out, so wait for the readout's completion tick.
    await pumpUntil(
      tester,
      () => find.byIcon(Icons.check_circle_outline).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 90),
      reason: 'thumbnails to finish generating',
    );
  }

  /// Drags a trim handle and holds it, pumping frames so ticker-driven
  /// auto-scroll can advance. Returns after the gesture is released.
  Future<void> dragHandleAndHold(
    WidgetTester tester, {
    required Offset from,
    required Offset by,
    int holdFrames = 90,
  }) async {
    final gesture = await tester.startGesture(from);
    await tester.pump();
    // Move in steps so the recognizer sees a real drag rather than a jump.
    const steps = 12;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(by.dx / steps, by.dy / steps));
      await tester.pump(const Duration(milliseconds: 16));
    }
    for (var i = 0; i < holdFrames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renders the trim viewer for the bundled sample', (tester) async {
    await openSampleTrimmer(tester);

    // A TrimViewer that never received its initialized event collapses to an
    // empty SizedBox, so a non-zero size is the regression guard.
    final size = tester.getSize(find.byType(TrimViewer));
    expect(size.width, greaterThan(100));
    expect(size.height, greaterThan(20));

    // The default config caps selection at 10s, so the initial window should
    // be non-empty and no longer than that.
    final length = readout('length');
    expect(length, greaterThan(0.5));
    expect(length, lessThanOrEqualTo(10.5));
  });

  testWidgets('the strip shows JPEG frames from the native thumbnailer',
      (tester) async {
    await openSampleTrimmer(tester);

    // Each loaded thumbnail is a FadeInImage over a transparent PNG
    // placeholder; its `image` holds the frame the plugin returned.
    final frames = find
        .descendant(
          of: find.byType(TrimViewer),
          matching: find.byType(FadeInImage),
        )
        .evaluate()
        .map((e) => (e.widget as FadeInImage).image)
        .whereType<MemoryImage>()
        .toList();
    expect(frames, isNotEmpty, reason: 'no thumbnails in the strip');
    for (final frame in frames) {
      // Every JPEG starts with the SOI marker FF D8.
      expect(frame.bytes.take(2), [0xFF, 0xD8]);
    }
  });

  /// Default `viewerHeight` from `TrimmerConfig`, and so the height of the
  /// thumbnail strip.
  const stripHeight = 50.0;

  /// A point inside the thumbnail strip, at [widthFraction] across it.
  ///
  /// `TrimViewer`'s own rect includes the duration labels stacked above the
  /// strip, so its centre lands in the wrong row; the strip is the bottom
  /// [stripHeight] pixels.
  Offset stripPoint(WidgetTester tester, double widthFraction) {
    final viewer = tester.getRect(find.byType(TrimViewer));
    return Offset(
      viewer.left + viewer.width * widthFraction,
      viewer.bottom - stripHeight / 2,
    );
  }

  testWidgets('dragging the frame into the edge zone auto-scrolls forward',
      (tester) async {
    await openSampleTrimmer(tester);

    final startBefore = readout('start');
    final endBefore = readout('end');

    // Grab the middle of the frame, which drags the whole window. Pushing it
    // against the right edge is what arms auto-scroll.
    await dragHandleAndHold(
      tester,
      from: stripPoint(tester, 0.35),
      by: const Offset(140, 0),
    );

    final startAfter = readout('start');
    final endAfter = readout('end');

    expect(endAfter, greaterThan(endBefore + 1.0),
        reason: 'end should advance once the strip scrolls');
    expect(startAfter, greaterThan(startBefore + 0.5),
        reason: 'start should follow the scroll');
    expect(endAfter, lessThanOrEqualTo(30.5),
        reason: 'selection must stay inside the clip');
  });

  testWidgets('the whole clip is reachable, not just the first trim area',
      (tester) async {
    // #192, #223, #207: with a 30 s clip and a 10 s max the strip shows
    // maxVideoLength * (1 + 2 * paddingFraction) = 14 s at a time, and the
    // rest is only reachable by scrolling. Scroll all the way, then push the
    // frame to the right edge: the selection must end on the clip's last
    // frame.
    await openSampleTrimmer(tester);

    final gesture = await tester.startGesture(stripPoint(tester, 0.35));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(16, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Hold in the edge zone until the strip has scrolled as far as it goes.
    ScrollPosition strip() => tester
        .widgetList<SingleChildScrollView>(find.descendant(
            of: find.byType(TrimViewer),
            matching: find.byType(SingleChildScrollView)))
        .first
        .controller!
        .position;
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (strip().pixels < strip().maxScrollExtent - 0.5 &&
        DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(strip().pixels, closeTo(strip().maxScrollExtent, 0.5),
        reason: 'auto-scroll should reach the end of the strip');
    // Then push the frame the rest of the way to the strip's right edge, as a
    // user would once the scrolling stops.
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(16, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));

    final end = readout('end');
    expect(end, greaterThanOrEqualTo(29.7),
        reason: 'the tail of the clip must be selectable');
    expect(end, lessThanOrEqualTo(30.1),
        reason: 'the selection must not run past the clip');
    expect(readout('length'), lessThanOrEqualTo(10.2),
        reason: 'reaching the end must keep the maxVideoLength cap');
  });

  testWidgets('a fast drag in the fixed viewer lands exactly on the edge',
      (tester) async {
    // Drags that would cross a bound used to be rejected outright, so a fast
    // drag stopped up to one pointer delta short of the strip's edge.
    await openSampleTrimmer(tester);
    await tester.tap(find.byKey(const Key('open_config')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('fixed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APPLY'));
    await pumpUntil(
      tester,
      () => find.byType(FixedTrimViewer).evaluate().isNotEmpty,
      reason: 'fixed viewer to mount',
    );
    await pumpUntil(
      tester,
      () => find.byIcon(Icons.check_circle_outline).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 90),
      reason: 'thumbnails to finish generating',
    );

    // Grab the middle of the 10 s frame and throw it right in big steps.
    final gesture = await tester.startGesture(stripPoint(tester, 0.15));
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(45, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));

    expect(readout('end'), closeTo(30.0, 0.15),
        reason: 'the frame should stop on the last frame of the clip');
    expect(readout('length'), closeTo(10.0, 0.15),
        reason: 'moving the frame must keep its length');
  });

  testWidgets('the right handle stays pinned at maxVideoLength',
      (tester) async {
    await openSampleTrimmer(tester);
    final lengthBefore = readout('length');

    // The default window is already at the 10s cap, so dragging the right
    // handle outwards must not lengthen it.
    await dragHandleAndHold(
      tester,
      from: stripPoint(tester, 0.73),
      by: const Offset(90, 0),
      holdFrames: 20,
    );

    expect(readout('length'), lessThanOrEqualTo(lengthBefore + 0.2),
        reason: 'selection must not grow past maxVideoLength');
  });

  testWidgets('dragging the strip itself moves the selection', (tester) async {
    await openSampleTrimmer(tester);

    // Push the window forward first, so there is scroll extent to travel back
    // through.
    await dragHandleAndHold(
      tester,
      from: stripPoint(tester, 0.35),
      by: const Offset(140, 0),
      holdFrames: 150,
    );
    final scrolledStart = readout('start');
    expect(scrolledStart, greaterThan(1.0),
        reason: 'precondition: strip should have scrolled forward');

    // Now drag the strip itself. After scrolling forward the frame has moved
    // right, so the far left of the strip is outside it — which is where the
    // trim-frame recognizer declines the pointer and the scroll view takes
    // over. Dragging content rightwards rewinds.
    await tester.dragFrom(stripPoint(tester, 0.11), const Offset(200, 0));
    await tester.pump(const Duration(milliseconds: 900));

    expect(readout('start'), lessThan(scrolledStart),
        reason: 'dragging the strip right should rewind the selection');
  });

  testWidgets('renders when mounted after the video already initialized',
      (tester) async {
    // Regression for the missed-event bug: TrimViewer waited on a broadcast
    // stream that never replays, so a viewer built after loadVideo() finished
    // stayed an empty SizedBox forever. Changing the config remounts the
    // viewer against an already-initialized controller, which is that path.
    await openSampleTrimmer(tester);

    await tester.tap(find.byKey(const Key('open_config')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('fixed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APPLY'));
    await pumpUntil(
      tester,
      () => find.byType(TrimViewer).evaluate().isNotEmpty,
      reason: 'TrimViewer to remount',
    );
    // Let the post-frame layout pass run.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final size = tester.getSize(find.byType(TrimViewer));
    expect(size.height, greaterThan(20),
        reason: 'remounted viewer collapsed to an empty box');
    expect(find.byType(FixedTrimViewer), findsOneWidget,
        reason: 'ViewerType.fixed should build the fixed viewer');
  });

  testWidgets('the Trimmer survives leaving and re-entering the trimmer',
      (tester) async {
    // Regression for VideoViewer.dispose() calling trimmer.dispose(): the
    // second load used to throw "Cannot add new events after calling close".
    await openSampleTrimmer(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('use_sample')), findsOneWidget);

    await tester.tap(find.byKey(const Key('use_sample')));
    await pumpUntil(
      tester,
      () => find.byType(TrimViewer).evaluate().isNotEmpty,
      reason: 'TrimViewer to mount a second time',
    );
    await pumpUntil(
      tester,
      () => find.byIcon(Icons.check_circle_outline).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 90),
      reason: 'thumbnails on the second load',
    );

    expect(tester.takeException(), isNull);
    expect(readout('length'), greaterThan(0.5),
        reason: 'second load should report a real trim window');
  });

  testWidgets('saves a trim to a path free of awkward characters',
      (tester) async {
    await openSampleTrimmer(tester);

    await tester.tap(find.byKey(const Key('save_video')));
    await pumpUntil(
      tester,
      () => find.text('Preview').evaluate().isNotEmpty,
      timeout: const Duration(seconds: 120),
      reason: 'the trim to finish and the preview to open',
    );

    // The preview prints the output path; issue #203 was colons and commas in
    // it breaking downstream media tooling.
    final pathFinder = find.textContaining('/Trimmer/');
    expect(pathFinder, findsOneWidget, reason: 'no output path on screen');
    final outputPath = (pathFinder.evaluate().single.widget as Text).data!;

    expect(outputPath, isNot(contains(':')));
    expect(outputPath, isNot(contains(',')));
    expect(outputPath, isNot(contains(' ')));
    expect(File(outputPath).existsSync(), isTrue,
        reason: 'trimmed file should exist at $outputPath');
    expect(File(outputPath).lengthSync(), greaterThan(0));
  });

  testWidgets('builds with every optional callback omitted', (tester) async {
    // Regression guard for the null check crash: TrimViewer used to
    // force-unwrap onChangeStart/onChangeEnd/onChangePlaybackState.
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      debugPrint('CAPTURED ERROR: ${details.exception}\n${details.stack}');
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await openSampleTrimmer(tester);

    await tester.tap(find.byKey(const Key('open_config')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('attach callbacks'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('APPLY'));
    await pumpUntil(
      tester,
      () => find.byType(TrimViewer).evaluate().isNotEmpty,
      reason: 'TrimViewer to rebuild without callbacks',
    );

    // Give the position listener plenty of frames to fire.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
  });

  // ---- Playback: looping, scrubber sync and speed (#237, #236, #137, #212,
  // #218) ----

  VideoPlayerController player(WidgetTester tester) =>
      tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller;

  TrimEditorPainter painter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.descendant(
        of: find.byType(TrimViewer),
        matching: find.byType(CustomPaint),
      ))
      .map((p) => p.foregroundPainter)
      .whereType<TrimEditorPainter>()
      .single;

  /// Pumps real frames for [d] so the player keeps running.
  Future<void> run(WidgetTester tester, Duration d) async {
    final until = DateTime.now().add(d);
    while (DateTime.now().isBefore(until)) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Where the scrubber should be for the player's reported position.
  double expectedScrubberX(WidgetTester tester) {
    final p = painter(tester);
    final start = readout('start') * 1000;
    final end = readout('end') * 1000;
    final pos = player(tester)
        .value
        .position
        .inMilliseconds
        .clamp(start, end)
        .toDouble();
    return p.startPos.dx +
        (pos - start) / (end - start) * (p.endPos.dx - p.startPos.dx);
  }

  /// A private copy of the bundled sample, for tests that build their own
  /// Trimmer instead of going through the example's pages.
  Future<File> sampleCopy(String name) async {
    final data = await rootBundle.load('assets/sample.mp4');
    final file = File('${(await getTemporaryDirectory()).path}/$name');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file;
  }

  testWidgets('without looping, playback pauses at the trim end',
      (tester) async {
    await openSampleTrimmer(tester);
    await player(tester).seekTo(const Duration(milliseconds: 8800));
    await tester.tap(find.byKey(const Key('play_pause')));
    // Wait on the outcome rather than a fixed time: a loaded emulator can
    // take a second or more just to start decoding.
    await pumpUntil(
      tester,
      () => player(tester).value.position.inMilliseconds >= 9800,
      timeout: const Duration(seconds: 15),
      reason: 'playback to reach the trim end',
    );
    await run(tester, const Duration(milliseconds: 800));

    expect(player(tester).value.isPlaying, isFalse);
    expect(player(tester).value.position.inMilliseconds,
        inInclusiveRange(9800, 10600));
    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget,
        reason: 'the play button should report the pause');
  });

  testWidgets('with looping on, playback wraps back to the trim start',
      (tester) async {
    await openSampleTrimmer(tester);
    await tester.tap(find.byKey(const Key('loop_toggle')));
    await tester.pump();
    expect(player(tester).value.isLooping, isTrue);

    await player(tester).seekTo(const Duration(milliseconds: 8800));
    await tester.tap(find.byKey(const Key('play_pause')));
    await pumpUntil(
      tester,
      () => player(tester).value.position.inMilliseconds >= 9500,
      timeout: const Duration(seconds: 15),
      reason: 'playback to approach the trim end',
    );
    // Then it must wrap to the start rather than stop.
    await pumpUntil(
      tester,
      () => player(tester).value.position.inMilliseconds < 3000,
      timeout: const Duration(seconds: 15),
      reason: 'playback to wrap back to the trim start',
    );
    await run(tester, const Duration(milliseconds: 300));

    final value = player(tester).value;
    expect(value.isPlaying, isTrue, reason: 'looping must not pause');
    expect(value.position.inMilliseconds, lessThan(3000),
        reason: 'should have wrapped to the trim start (0 s)');
    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
  });

  testWidgets('the scrubber tracks the player through repeated pauses',
      (tester) async {
    await openSampleTrimmer(tester);
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byKey(const Key('play_pause')));
      await run(tester, const Duration(milliseconds: 450));
      await tester.tap(find.byKey(const Key('play_pause')));
      await run(tester, const Duration(milliseconds: 250));
    }
    expect(player(tester).value.isPlaying, isFalse);
    final position = player(tester).value.position.inMilliseconds;
    expect(position, greaterThan(2000), reason: 'precondition: it played');
    expect(painter(tester).scrubberAnimationDx,
        closeTo(expectedScrubberX(tester), 1.5),
        reason: 'paused scrubber must sit on the paused frame');
  });

  testWidgets('the scrubber follows playback speed', (tester) async {
    await openSampleTrimmer(tester);
    await tester.tap(find.byKey(const Key('speed_toggle'))); // 1.5x
    await tester.pump();
    await tester.tap(find.byKey(const Key('speed_toggle'))); // 2x
    await tester.pump();
    expect(player(tester).value.playbackSpeed, 2.0);

    await tester.tap(find.byKey(const Key('play_pause')));
    await run(tester, const Duration(milliseconds: 1500));
    // Sample mid-playback: the estimate may lead the last report by at most
    // one update interval at 2x.
    expect(painter(tester).scrubberAnimationDx,
        closeTo(expectedScrubberX(tester), 12),
        reason: 'scrubber should move at the player\'s speed');
    await tester.tap(find.byKey(const Key('play_pause')));
    await run(tester, const Duration(milliseconds: 300));

    expect(player(tester).value.position.inMilliseconds, greaterThan(2400),
        reason: '1.5 s at 2x should cover about 3 s of video');
    expect(painter(tester).scrubberAnimationDx,
        closeTo(expectedScrubberX(tester), 1.5));
  });

  testWidgets(
      'a consumer that seeks from onChangePlaybackState does not re-enter',
      (tester) async {
    // #236: onChangePlaybackState used to fire on every position update, so
    // a callback that seeks or plays re-triggered itself until the stack
    // overflowed. It must only fire on transitions now.
    final file = await sampleCopy('loop.mp4');

    final trimmer = Trimmer();
    addTearDown(trimmer.dispose);
    await trimmer.loadVideo(videoFile: file);
    final reports = <bool>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: TrimViewer(
            trimmer: trimmer,
            viewerWidth: 360,
            viewerHeight: 50,
            maxVideoLength: const Duration(seconds: 10),
            onChangePlaybackState: (playing) {
              reports.add(playing);
              // The pattern from the issue: rewind whenever playback stops.
              if (!playing) {
                trimmer.videoPlayerController!.seekTo(Duration.zero);
              }
            },
          ),
        ),
      ),
    ));
    await run(tester, const Duration(seconds: 2));

    await trimmer.videoPlayerController!.play();
    await run(tester, const Duration(seconds: 2));
    await trimmer.videoPlayerController!.pause();
    await run(tester, const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(reports.where((p) => p).length, 1,
        reason: 'one report per start, not one per position update');
    expect(reports.last, isFalse);
  });

  // ---- Initial trim range (#73, #274, #209) ----

  for (final type in [ViewerType.fixed, ViewerType.scrollable]) {
    testWidgets('the ${type.name} viewer opens on initialStart/EndValue',
        (tester) async {
      final file = await sampleCopy('initial_${type.name}.mp4');
      final trimmer = Trimmer();
      addTearDown(trimmer.dispose);
      await trimmer.loadVideo(videoFile: file);

      double? start;
      double? end;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: TrimViewer(
              trimmer: trimmer,
              type: type,
              viewerWidth: 360,
              viewerHeight: 50,
              maxVideoLength: const Duration(seconds: 10),
              initialStartValue: 12000,
              initialEndValue: 18000,
              onChangeStart: (v) => start = v,
              onChangeEnd: (v) => end = v,
            ),
          ),
        ),
      ));
      await run(tester, const Duration(seconds: 2));

      expect(start, closeTo(12000, 60), reason: 'reported start');
      expect(end, closeTo(18000, 60), reason: 'reported end');
      expect(trimmer.videoPlayerController!.value.position.inMilliseconds,
          closeTo(12000, 200),
          reason: 'the preview should open on the restored start');

      // The frame is drawn where the range is: 6 s of a strip that shows
      // either the whole 30 s (fixed) or about 14 s (scrollable).
      final p = painter(tester);
      final strip = tester.getSize(find.byType(TrimViewer)).width;
      final widthMs = type == ViewerType.fixed ? 30000 : 14000;
      expect(p.endPos.dx - p.startPos.dx, closeTo(6000 / widthMs * strip, 25));
      expect(p.startPos.dx, greaterThanOrEqualTo(0));
      expect(p.endPos.dx, lessThanOrEqualTo(strip + 1));

      if (type == ViewerType.scrollable) {
        final scroll = tester
            .widgetList<SingleChildScrollView>(find.descendant(
                of: find.byType(TrimViewer),
                matching: find.byType(SingleChildScrollView)))
            .first
            .controller!
            .position;
        expect(scroll.pixels, greaterThan(0),
            reason: 'the strip should scroll the restored range into view');
      }
    });
  }

  testWidgets('reopening a video restores its last selection', (tester) async {
    await openSampleTrimmer(tester);
    await dragHandleAndHold(
      tester,
      from: stripPoint(tester, 0.35),
      by: const Offset(140, 0),
      holdFrames: 120,
    );
    final start = readout('start');
    final end = readout('end');
    expect(start, greaterThan(1.0), reason: 'precondition: moved off 0');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('use_sample')));
    await pumpUntil(
      tester,
      () => find.byIcon(Icons.check_circle_outline).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 90),
      reason: 'trimmer to reopen',
    );
    await run(tester, const Duration(milliseconds: 500));

    expect(readout('start'), closeTo(start, 0.06));
    expect(readout('end'), closeTo(end, 0.06));
  });

  // ---- minVideoLength (#188, #269) ----

  /// Global position of a handle, read off the painter.
  Offset handleAt(WidgetTester tester, {required bool end}) {
    final paintFinder = find.descendant(
      of: find.byType(TrimViewer),
      matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.foregroundPainter is TrimEditorPainter),
    );
    final p = painter(tester);
    final box = tester.getRect(paintFinder.first);
    final x = end ? p.endPos.dx : p.startPos.dx;
    return Offset(box.left + x, box.top + box.height / 2);
  }

  Future<void> dragFrom(WidgetTester tester, Offset from, double dx) async {
    final g = await tester.startGesture(from);
    await tester.pump();
    final steps = (dx.abs() / 12).ceil();
    for (var i = 0; i < steps; i++) {
      await g.moveBy(Offset(dx / steps, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<({double Function() start, double Function() end})> pumpMinViewer(
    WidgetTester tester, {
    required ViewerType type,
    required Duration min,
    required Duration max,
  }) async {
    final file = await sampleCopy('min_${type.name}.mp4');
    final trimmer = Trimmer();
    addTearDown(trimmer.dispose);
    await trimmer.loadVideo(videoFile: file);
    var start = 0.0;
    var end = 0.0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: TrimViewer(
            trimmer: trimmer,
            type: type,
            viewerWidth: 360,
            viewerHeight: 50,
            maxVideoLength: max,
            minVideoLength: min,
            onChangeStart: (v) => start = v,
            onChangeEnd: (v) => end = v,
          ),
        ),
      ),
    ));
    await run(tester, const Duration(seconds: 2));
    return (start: () => start, end: () => end);
  }

  for (final type in [ViewerType.fixed, ViewerType.scrollable]) {
    testWidgets('the ${type.name} viewer keeps the selection >= minVideoLength',
        (tester) async {
      final values = await pumpMinViewer(tester,
          type: type,
          min: const Duration(seconds: 4),
          max: const Duration(seconds: 10));

      // Pull the right handle far left, past the left one.
      await dragFrom(tester, handleAt(tester, end: true), -320);
      expect(values.end() - values.start(), closeTo(4000, 80),
          reason: 'the right handle should stop 4 s after the start');

      // Push the left handle far right, past the right one.
      await dragFrom(tester, handleAt(tester, end: false), 320);
      expect(values.end() - values.start(), closeTo(4000, 80),
          reason: 'the left handle should stop 4 s before the end');
    });
  }

  testWidgets('minVideoLength == maxVideoLength makes a fixed-length frame',
      (tester) async {
    final values = await pumpMinViewer(tester,
        type: ViewerType.fixed,
        min: const Duration(seconds: 6),
        max: const Duration(seconds: 6));
    expect(values.end() - values.start(), closeTo(6000, 60));

    await dragFrom(tester, handleAt(tester, end: true), -120);
    await dragFrom(tester, handleAt(tester, end: false), 120);
    expect(values.end() - values.start(), closeTo(6000, 60),
        reason: 'neither handle can change the length');

    // The frame still moves as a whole.
    final before = values.start();
    final mid = Offset.lerp(
        handleAt(tester, end: false), handleAt(tester, end: true), 0.5)!;
    await dragFrom(tester, mid, 90);
    expect(values.start(), greaterThan(before + 1000));
    expect(values.end() - values.start(), closeTo(6000, 60));
  });
}

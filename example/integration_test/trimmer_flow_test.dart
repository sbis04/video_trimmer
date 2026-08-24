import 'dart:io';

import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
}

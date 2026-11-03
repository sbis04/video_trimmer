## 6.0.0

The biggest update since the native rewrite. It adds macOS and web support,
fixes the crashes and dead-UI reports that new integrations hit first, moves
thumbnails and trimming into the package's own native code, reworks scrolling
and playback, and adds line handles, `minVideoLength`, and restoring a saved
selection. See the README's "Migrating to 6.0.0" section when upgrading.

#### BREAKING CHANGES

* `Trimmer.loadVideo` takes the video's path (`videoPath`) instead of a
  `dart:io` `File`, so the same code runs on the web: replace
  `loadVideo(videoFile: file)` with `loadVideo(videoPath: file.path)`. On the
  web, pass a blob: URL, such as a picker's `XFile.path`.
  `Trimmer.currentVideoFile` is now `currentVideoPath`.
* The viewer widgets no longer dispose the `VideoPlayerController` or the
  `Trimmer`. The `Trimmer` owns the controller, and `Trimmer.dispose()`
  releases it. Call `Trimmer.dispose()` from the `State` that created the
  instance. ([#250])
* video_trimmer is now a Flutter plugin with its own native code for
  thumbnails and trimming: AVFoundation on iOS, Media3 Transformer on Android.
  `get_thumbnail_video` and `flutter_native_video_trimmer` are no longer
  dependencies. Run `flutter clean` (and `pod install` on iOS) if a build
  picks up stale plugin registrations.
* The Android `minSdk` is 24, the minimum `video_player_android` already
  requires.
* A trimmed video's extension matches the container actually written:
  always `.mp4` on Android, and `.mp4` on iOS and macOS except for `.mov` and
  `.m4v` sources, which keep theirs. It used to copy the source's extension,
  so a `.webm` or `.mkv` source on Android produced MP4 data under that name.
* `onChangePlaybackState` fires only when playback starts or stops, not on
  every position update. ([#236])
* `Trimmer.loadVideo` throws a `FileSystemException` on native platforms when
  the file does not exist, instead of silently doing nothing.
* Default output file names changed from
  `<name>_trimmed:<localized date>.<ext>` to
  `<name>_trimmed_<yyyyMMdd_HHmmss>.<ext>`. ([#203], [#214])
* `DurationStyle` no longer truncates the largest unit it is asked for:
  `FORMAT_MM_SS` renders 1h30m15s as `90:15` rather than `30:15`, and
  `FORMAT_SS` renders 90s as `90` rather than `30`.
* `StorageDir` is now a real `enum`. Existing call sites
  (`StorageDir.temporaryDirectory`, `.values`, `.index`, `toString()`) behave
  as before, but it can no longer be subclassed.
* `ViewerType.scrollable` on a video too short to scroll now reports a Flutter
  error and falls back to the fixed viewer, rather than throwing a bare
  `String` from a stream listener.
* The trim handles are drawn as lines instead of dots by default. Pass
  `TrimEditorProperties(handleStyle: TrimHandleStyle.circle)` to keep the
  previous look.

#### New

* Web support. Thumbnails are drawn from a `<video>` element, and trimming
  runs in the browser with [Mediabunny](https://github.com/Vanilagy/mediabunny)
  (MPL-2.0) on WebCodecs, producing MP4. `onSave` receives a blob: URL, and
  GIF output works too. Mediabunny is embedded in the web plugin only, so
  apps on other platforms don't carry it. No part of the package's shared
  code imports `dart:io` any more, and it also compiles to WebAssembly.
* macOS support. The iOS plugin code now lives in `darwin/` and is shared
  with macOS (`sharedDarwinSource`), so thumbnails and trimming use the same
  AVFoundation code on both. JPEG encoding moved from UIKit to ImageIO for
  that. The example app runs on macOS too.
* Line drag handles. `TrimEditorProperties.handleStyle` picks
  `TrimHandleStyle.line` (the new default) or `TrimHandleStyle.circle`, and
  `handleHeight` sets a line's height in pixels or as a percentage of the trim
  area: `TrimHandleHeight.pixels(24)` or `TrimHandleHeight.percent(50)` (the
  default). `circleSize` and `circleSizeOnDrag` set the line's width, so it
  still grows while it is dragged.
* `TrimViewer.minVideoLength` sets the shortest selection allowed. The
  handles stop rather than close in past it, and a saved range shorter than
  it grows to fit. Set it equal to `maxVideoLength` for a fixed-length
  selection that can only be moved. ([#188], [#269])
* `TrimViewer` takes `initialStartValue` / `initialEndValue` (milliseconds,
  the same values `onChangeStart` / `onChangeEnd` report) to open on a saved
  selection. Both viewers honor them; the scrollable viewer scrolls the range
  into view, and the preview starts on its first frame. Either can be given
  alone, so `initialEndValue` also sets a shorter default selection than
  `maxVideoLength`. ([#73], [#274], [#209])
* Smoother scrolling: the scrollable viewer's auto-scroll advances once per
  frame instead of hopping on a 300 ms timer, its trigger zone is touch-sized
  rather than 2% of the strip width, and the thumbnail strip can be dragged
  directly with a fling on release. ([#187], [#263])
* Drag start picks the nearest handle within `sideTapSize` instead of slicing
  the frame into zones, so grabs near either end no longer move both
  handles. ([#234])
* New `TrimAreaProperties` options: `allowManualScroll`, `autoScrollEdgeZone`,
  `maxAutoScrollVelocity`, and `autoScrollStartDelay`. ([#199])
* Looping works inside the trim range. With
  `videoPlayerController.setLooping(true)`, playback wraps from the trim end
  back to the trim start instead of pausing, including when the range ends at
  the end of the video and the player loops on its own. ([#237]) Playback
  stops or wraps at the trim end within a frame, instead of overshooting it by
  up to one of the player's position reports, and a wrap at the end of the
  video no longer flashes the video's first frame.
* The scrubber follows the player's real position and playback speed instead
  of running its own clock, so it no longer drifts after repeated pauses and
  stays correct at 0.5x–2x. ([#137], [#212], [#218])
* Swift Package Manager support on iOS. With `flutter_native_video_trimmer`
  gone, no dependency of the package lacks it, so iOS builds no longer warn.
* Trimming writes straight to the destination instead of exporting to the
  cache and copying the result. Android uses Media3's trim optimization,
  which copies the samples it can instead of re-encoding them.

#### Fixes

* Apps that also depend on `video_thumbnail` no longer crash at launch on iOS
  with `Duplicate plugin key: VideoThumbnailPlugin`. The `get_thumbnail_video`
  dependency, and its `libwebp` pod, are gone. ([#271], [#266], [#275])
* `TrimViewer` and `VideoViewer` rendered nothing forever when the video
  finished initializing before they mounted — the `await loadVideo()` then
  `setState` pattern, conditional builds, and hot reload. They now check the
  `Trimmer`'s state directly. ([#215])
* Omitting `onChangeStart`, `onChangeEnd`, or `onChangePlaybackState` threw
  `Null check operator used on a null value`. ([#268])
* Callbacks that seek or play from `onChangePlaybackState` no longer re-enter
  until the stack overflows. ([#236])
* On Android, disposing a `Trimmer` (for example by leaving the page) while
  its video was still loading made that load hang forever and could stall the
  next one. A controller is now released only after its `initialize()`
  settles.
* `Trimmer.dispose()` while `loadVideo` was still running left a live,
  initialized player behind, and two overlapping `loadVideo` calls both
  emitted `initialized` and leaked the loser's player. Now the newest call
  wins, a disposed `Trimmer` ignores `loadVideo`, and superseded loads release
  everything they created.
* `saveTrimmedVideo` calls `onSave(null)` when the native trimmer produces no
  file, instead of throwing a null-check error.
* `saveTrimmedVideo` dereferenced a null directory when
  `StorageDir.externalStorageDirectory` was used off Android, and when the
  storage value did not match its string-based switch. It now throws a clear
  `UnsupportedError`. ([#225])
* The scrollable viewer could not select the last part of a clip: with a 30 s
  clip and a 10 s max, the selection stopped 0.6–0.8 s before the end,
  depending on screen width. The scroll range now covers exactly what the
  visible area doesn't. ([#192], [#223], [#207])
* Fast drags in both viewers stop exactly on the strip's edge, the
  `maxVideoLength` cap, or the other handle, instead of up to one pointer
  delta short. Diagonal drags no longer shift the handles vertically.
* `intl` is accepted from 0.19.0, so apps whose Flutter SDK pins it through
  `flutter_localizations` resolve again. ([#261])
* `path` is accepted from 1.9.0. Flutter SDKs that pin `path` 1.9.0 through
  `flutter_test`, such as 3.22, could not resolve the package at all.
* The supported range is now declared: Flutter 3.22 or later (Dart 3.4),
  which the dependencies already required. It is verified by analyzing and
  unit-testing the package on Flutter 3.22.3.
* `videoPlaybackControl` starts from the trim start when the playhead is
  before it, not only after the end.
* Both viewers invoked consumer callbacks from `dispose()`, which runs inside a
  locked build scope, so any consumer calling `setState` there crashed on
  teardown.
* Neither viewer removed its video-player listener, so `dispose()`'s `pause()`
  notified it synchronously and crashed the same way.
* Default output names no longer truncate source file names containing dots:
  `my.holiday.clip.mp4` kept only `my`.
* `VideoViewer`'s `padding` argument was accepted and then ignored.
* `TrimAreaProperties.edgeBlur()` declared `startIcon`, `endIcon`, and
  `blurEdges` as untyped parameters and never forwarded them, so custom icons
  were silently discarded.
* The decorative edge chevrons hit-tested as opaque and swallowed drags right
  where users reach to scroll.
* `Trimmer.loadVideo` leaked the previous `VideoPlayerController` on every
  reload, and the viewers' scrubber animation controllers and stream
  subscriptions were never disposed.

#### Other changes

* Dependencies upgraded: `image` 4.12, `video_player` 2.14, `flutter_lints` 6.
* `intl`, `transparent_image`, and `flutter_native_video_trimmer` are no
  longer dependencies. `intl` was only used to format output file names, and
  its version is pinned by the Flutter SDK through `flutter_localizations`, so
  every `intl` release risked a version conflict for apps that localize.
  `transparent_image` supplied one placeholder image, now part of the
  package.
* Export `FixedTrimViewer` and `ScrollableTrimViewer` so they can be used and
  tested directly.
* README rewritten for 6.0.0: up-to-date usage, a migration guide, a full
  example that compiles against the current API, a new demo that also
  renders on pub.dev, a new cover, and a labeled TrimViewer diagram.
* The example is now a customization playground covering every option, with
  loop and speed controls, per-file selection restore, a bundled sample clip,
  no iOS swipe-back on the trimmer page (it stole drags on the start handle),
  and the Flutter 3.47 Android template (Gradle 9.3, AGP 9.1, Kotlin 2.4).
* Unit tests for the pure logic (drag clamping, initial ranges, playhead,
  naming, durations) and an integration suite of 25 tests that drives the
  example app on iOS and Android.

[#73]: https://github.com/sbis04/video_trimmer/issues/73
[#137]: https://github.com/sbis04/video_trimmer/issues/137
[#187]: https://github.com/sbis04/video_trimmer/issues/187
[#188]: https://github.com/sbis04/video_trimmer/issues/188
[#192]: https://github.com/sbis04/video_trimmer/issues/192
[#199]: https://github.com/sbis04/video_trimmer/issues/199
[#203]: https://github.com/sbis04/video_trimmer/issues/203
[#207]: https://github.com/sbis04/video_trimmer/issues/207
[#209]: https://github.com/sbis04/video_trimmer/issues/209
[#212]: https://github.com/sbis04/video_trimmer/issues/212
[#214]: https://github.com/sbis04/video_trimmer/issues/214
[#215]: https://github.com/sbis04/video_trimmer/issues/215
[#218]: https://github.com/sbis04/video_trimmer/issues/218
[#223]: https://github.com/sbis04/video_trimmer/issues/223
[#225]: https://github.com/sbis04/video_trimmer/issues/225
[#234]: https://github.com/sbis04/video_trimmer/issues/234
[#236]: https://github.com/sbis04/video_trimmer/issues/236
[#237]: https://github.com/sbis04/video_trimmer/issues/237
[#250]: https://github.com/sbis04/video_trimmer/issues/250
[#261]: https://github.com/sbis04/video_trimmer/issues/261
[#263]: https://github.com/sbis04/video_trimmer/issues/263
[#266]: https://github.com/sbis04/video_trimmer/issues/266
[#268]: https://github.com/sbis04/video_trimmer/issues/268
[#269]: https://github.com/sbis04/video_trimmer/issues/269
[#271]: https://github.com/sbis04/video_trimmer/issues/271
[#274]: https://github.com/sbis04/video_trimmer/issues/274
[#275]: https://github.com/sbis04/video_trimmer/issues/275

## 5.0.0

Got rid of the `flutter_ffmpeg` package and now uses a **native video trimmer** (Android and iOS)! 🎉

#### Why the change?

* The most important reason is that the `flutter_ffmpeg` package has been discontinued by the author. Learn more about it [here](https://tanersener.medium.com/saying-goodbye-to-ffmpegkit-33ae939767e1).
* The native video trimmer is more efficient and faster. And even provides better performance with low memory usage.

#### BREAKING CHANGES

* Remove `ffmpegCommand` and `customVideoFormat` properties. As those were specific to `flutter_ffmpeg` package.
* `FileFormat` no longer exists. A new enum is introduced called `OutputType` to choose between GIF and video output file.
* `outputFormat` no longer exists. By default the output has the same format as the original video.

#### Other changes

* New property `qualityGIF` to specify the quality of the GIF.
* Update dependencies.
* Update example project.
* Update README.

## 4.0.2

* Use `withValues` instead of `withOpacity` as it's deprecated.

## 4.0.1

* Update readme.

## 4.0.0

* Fix thumbnail loading issue while using certain video formats.
* Upgrade dependencies and remove `video_thumbnail` package (uses FFmpeg which is more reliable and efficient).
* Fix an issue with the video trimmer length being incorrectly calculated breaking the UI.

## 3.0.1

* Updates readme.

## 3.0.0

* **NOTE:** Separates the LTS version into a branched package version. By default, it will use the latest "Full" version of FFmpeg. To install the "LTS" version use the "x.x.x-LTS" version of the package.
* Updates minimum Flutter version to 3.0.
* Updates plugin versions.

## 2.1.0

* Update plugin versions.

## 2.0.1

* Add new property for specifying `DurationStyle`.

## 2.0.0

* **BREAKING CHANGE:** Overhaul of the entire video trimmer implementation.
  * Two types of `TrimViewer` are available: `FixedTrimViewer` & `ScrollableTrimViewer`. By default it's set to `auto` so that it switches between these two based on the total video length and the maximum trim duration allowed.
  * Rename `TrimEditor` to `TrimViewer`. Check out [this diagram](https://raw.githubusercontent.com/sbis04/video_trimmer/new_editor/screenshots/trim_viewer_preview_small.png) for better understanding of the keywords/terms.
  * Separate the properties of into two types, `TrimEditorProperties` & `TrimAreaProperties`. Helps in identifying where the properties belong to easily.
  * Fix some bugs related to wrong trimmer length while initialization.
* Add more customization options.
* Improve the documentation.
* Update the example project.
* Bug Fix: Use `circleSizeOnDrag` only on the selected holder.

## 1.2.0

* Update plugin versions.

## 1.1.3

* Changing `path` version to `1.8.0` (latest is `1.8.1`) because it creates a conflict with `flutter_test` as it uses the older version.

## 1.1.2

* Update plugin versions.

## 1.1.1

* Format file (to pass static analysis).

## 1.1.0

* Update ffmpeg_kit_flutter to 4.5.1-LTS.
* Update other plugin versions.
* Update Readme.

## 1.0.0

* **BREAKING CHANGE:** Migrate to [FFmpegKit for Flutter](https://pub.dev/packages/ffmpeg_kit_flutter).
  `saveTrimmedVideo()` method is not async now, you'll need to use the callback `onSave: (outputPath) {}` to get the trimmed video output path.
* Add playback timestamp in the `showDuration`.
* Simply configuration.
* Update the plugin versions.
* Update Docs.

## 0.6.0

* Update the plugin versions.
* Using flutter_lints.

## 0.5.4

* Update Docs.

## 0.5.3

* Add `borderWidth` and `scrubberWidth` properties under `TrimEditor` widget.
* Fix padding and border decoration of `VideoViewer`.
* Update the plugin versions.

## 0.5.2

* Fix iOS error while loading thumbnails in `TrimEditor`.
* Remove an unused dependency.
* Update packages.

## 0.5.1

* Update the example in Readme.
* Update the plugin versions.

## 0.5.0

* Global refactoring, example is now a standalone screen.
* Fixed the staggering issue when dragging the frame.
* The whole frame can now be dragged in addition to the sides.
* Updated packages.
* Updated the example.

## 0.4.0

* Migrate to null safety.
* Fix video thumbnail loading issues.
* Bump up all dependencies.
* Upgrade example.

## 0.3.5

* Update example app (small bug fixes).
* Update to latest plugin versions.

## 0.3.4

* Fixed the issue with video getting struck for a few initial frames during playback.

## 0.3.3

* Updated plugin versions.

## 0.3.2

* Minor changes.

## 0.3.1

* Improve the file structure of the package.
* Now, you just have to import one file for using the package.

## 0.3.0

* Update the plugin versions.
* Update example app (now includes how to retrieve the trimmed video).
* Update Readme.
* Fixes some memory leak issues.

## 0.2.7

* Add a new property called `maxVideoLength` for specifying the max length of the output video.
* Update Docs.

## 0.2.6

* Add a new property called `fit` to `TrimEditor` widget which will let you specify the image fit type of each thumbnail image.
* Add a new property to `saveTrimmedVideo()` method called `applyVideoEncoding` which will let you specify whether to re-encode the trimmed video. 
  
  **NOTE:** Applying this will take significantly greater amount of time to process the output video.

* Improve Docs.

## 0.2.5

* Update Docs.
* Reverted the FFmpeg trimmed video start & end position to **milliseconds** (earlier it was changed to **seconds** in `v0.2.4` to fix video freezing, but after testing it was found that the issue still persists).

## 0.2.4

* Fix output video freezing during start and end.
* Update the example app to use LTS version of FFmpeg (for wider device support).
* Update Readme.

## 0.2.3

* Fix issue with path returned.

## 0.2.2

* Change implementation of the `saveTrimmedVideo()` method.
* `saveTrimmedVideo()` now returns the output video path.
* Update Docs.

## 0.2.1

* Fix over-scrolling && scroll-over issue.

## 0.2.0

* BREAKING CHANGE: `loadVideo()` method implementation changed.
  Now, you can pass the video file to the method.
* Fix issue related to animation controller improperly disposing.
* Update Docs.

## 0.1.5

* Fix for paths having white spaces.

## 0.1.4

* Smoothen the scrubber animation.

## 0.1.3

* Code improvements.
* Update Readme.

## 0.1.2

* Changed `StorageDir` format naming.
* Update documentation.

## 0.1.1

* Correct documentation.

## 0.1.0

* Initial Open Source release.

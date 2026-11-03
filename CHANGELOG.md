## 6.0.0

Bug-fix release focused on the crashes and dead-UI reports that new
integrations hit first, plus a rework of the scrollable timeline.

#### Smoother scrolling

* The scrollable trim viewer's auto-scroll now advances once per frame instead
  of hopping on a 300 ms timer, and its trigger zone is touch-sized rather than
  2% of the strip width. ([#187], [#263])
* The thumbnail strip can be dragged directly, with a fling on release.
* Drag start picks the nearest handle within `sideTapSize` instead of slicing
  the frame into zones, so grabs near either end no longer move both
  handles. ([#234])
* New `TrimAreaProperties` options: `allowManualScroll`, `autoScrollEdgeZone`,
  `maxAutoScrollVelocity`, and `autoScrollStartDelay` ([#199]).

#### BREAKING CHANGES

* `StorageDir` is now a real `enum`. Existing call sites
  (`StorageDir.temporaryDirectory`, `.values`, `.index`, `toString()`) behave
  as before, but it can no longer be subclassed.
* The viewer widgets no longer dispose the `VideoPlayerController`. The
  `Trimmer` owns it, and `Trimmer.dispose()` now releases it. Call
  `Trimmer.dispose()` from the `State` that created the instance. ([#250])
* `VideoViewer` no longer calls `Trimmer.dispose()`. It only owns its own
  stream subscription.
* `Trimmer.loadVideo` throws a `FileSystemException` when the file does not
  exist, instead of silently doing nothing.
* Default output file names changed from
  `<name>_trimmed:<localized date>.<ext>` to
  `<name>_trimmed_<yyyyMMdd_HHmmss>.<ext>`. ([#203], [#214])
* `DurationStyle` no longer truncates the largest unit it is asked for:
  `FORMAT_MM_SS` renders 1h30m15s as `90:15` rather than `30:15`, and
  `FORMAT_SS` renders 90s as `90` rather than `30`.
* `ViewerType.scrollable` on a video too short to scroll now reports a Flutter
  error and falls back to the fixed viewer, rather than throwing a bare
  `String` from a stream listener.

#### Fixes

* Looping now works inside the trim range. With
  `videoPlayerController.setLooping(true)`, playback wraps from the trim end
  back to the trim start instead of pausing. ([#237])
* `onChangePlaybackState` fires only when playback starts or stops, not on
  every position update. Callbacks that seek or play from it no longer
  re-enter until the stack overflows. ([#236])
* The scrubber follows the player's real position and playback speed instead
  of running its own clock, so it no longer drifts after repeated pauses and
  stays correct at 0.5x–2x. ([#137], [#212], [#218])
* `videoPlaybackControl` starts from the trim start when the playhead is
  before it, not only after the end.
* The viewers' scrubber animation controllers were never disposed. They are
  replaced by a single ticker that is.
* The scrollable viewer could not select the last part of a clip: with a 30 s
  clip and a 10 s max, the selection stopped 0.6–0.8 s before the end,
  depending on screen width. The scroll range now covers exactly what the
  visible area doesn't. ([#192], [#223], [#207])
* Fast drags in both viewers stop exactly on the strip's edge, the
  `maxVideoLength` cap, or the other handle, instead of up to one pointer
  delta short. Diagonal drags no longer shift the handles vertically.
* Apps that also depend on `video_thumbnail` no longer crash at launch on iOS
  with `Duplicate plugin key: VideoThumbnailPlugin`. Thumbnails now come from
  this package's own native code instead of `get_thumbnail_video`, so that
  dependency (and its `libwebp` pod) is gone. ([#271], [#266], [#275])
* `intl` is accepted from 0.19.0, so apps whose Flutter SDK pins it through
  `flutter_localizations` resolve again. ([#261])
* `TrimViewer` and `VideoViewer` rendered nothing forever when the video
  finished initializing before they mounted — the `await loadVideo()` then
  `setState` pattern, conditional builds, and hot reload. They now check the
  `Trimmer`'s state directly. ([#215])
* Omitting `onChangeStart`, `onChangeEnd`, or `onChangePlaybackState` threw
  `Null check operator used on a null value`. ([#268])
* Both viewers invoked consumer callbacks from `dispose()`, which runs inside a
  locked build scope, so any consumer calling `setState` there crashed on
  teardown.
* Neither viewer removed its video-player listener, so `dispose()`'s `pause()`
  notified it synchronously and crashed the same way.
* `saveTrimmedVideo` dereferenced a null directory when
  `StorageDir.externalStorageDirectory` was used off Android, and when the
  storage value did not match its string-based switch. It now throws a clear
  `UnsupportedError`. ([#225])
* Default output names no longer truncate source file names containing dots:
  `my.holiday.clip.mp4` kept only `my`.
* `VideoViewer`'s `padding` argument was accepted and then ignored.
* `TrimAreaProperties.edgeBlur()` declared `startIcon`, `endIcon`, and
  `blurEdges` as untyped parameters and never forwarded them, so custom icons
  were silently discarded.
* The decorative edge chevrons hit-tested as opaque and swallowed drags right
  where users reach to scroll.
* `Trimmer.loadVideo` leaked the previous `VideoPlayerController` on every
  reload.
* `TrimViewer` and `VideoViewer` never cancelled their stream subscriptions.

#### Other changes

* video_trimmer is now a Flutter plugin (Android and iOS) and supports Swift
  Package Manager.
* Dependencies upgraded: `image` 4.12, `video_player` 2.14, `flutter_lints` 6.
  The example moves to `file_picker` 13 and the Flutter 3.47 Android template
  (Gradle 9.3, AGP 9.1, Kotlin 2.4).
* Export `FixedTrimViewer` and `ScrollableTrimViewer` so they can be used and
  tested directly.
* Add a unit test suite, and an integration test suite that drives the example
  app against a bundled sample clip.
* Rebuild the example as a customization playground covering every option the
  package exposes.

[#137]: https://github.com/sbis04/video_trimmer/issues/137
[#187]: https://github.com/sbis04/video_trimmer/issues/187
[#192]: https://github.com/sbis04/video_trimmer/issues/192
[#199]: https://github.com/sbis04/video_trimmer/issues/199
[#203]: https://github.com/sbis04/video_trimmer/issues/203
[#207]: https://github.com/sbis04/video_trimmer/issues/207
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
[#271]: https://github.com/sbis04/video_trimmer/issues/271
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

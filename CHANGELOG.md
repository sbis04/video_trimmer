## 0.2.5 - beta

* Update Docs
* Reverted the FFmpeg trimmed video start & end position to **milliseconds** (earlier it was changed to **seconds** in `v0.2.4` to fix video freezing, but after testing it was found that the issue still persists)

## 0.2.4 - beta

* Fix output video freezing during start and end
* Update the example app to use LTS version of FFmpeg (for wider device support)
* Update Readme

## 0.2.3 - beta

* Fix issue with path returned

## 0.2.2 - beta

* Change implementation of the `saveTrimmedVideo()` method
* `saveTrimmedVideo()` now returns the output video path
* Update Docs

## 0.2.1 - beta

* Fix over-scrolling && scroll-over issue

## 0.2.0 - beta

* BREAKING CHANGE: `loadVideo()` method implementation changed.
  Now, you can pass the video file to the method.
* Fix issue related to animation controller improperly disposing
* Update Docs

## 0.1.5 - beta

* Fix for paths having white spaces

## 0.1.4 - beta

* Smoothen the scrubber animation

## 0.1.3 - beta

* Code improvements
* Update Readme

## 0.1.2 - beta

* Changed `StorageDir` format naming
* Update documentation

## 0.1.1 - beta

* Correct documentation

## 0.1.0 - beta

* Initial Open Source release

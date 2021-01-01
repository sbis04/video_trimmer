## 0.3.5 - beta

* Update example app (small bug fixes)
* Update to latest plugin versions

## 0.3.4 - beta

* Fixed the issue with video getting struck for a few initial frames during playback

## 0.3.3 - beta

* Updated plugin versions

## 0.3.2 - beta

* Minor changes

## 0.3.1 - beta

* Improve the file structure of the package
* Now, you just have to import one file for using the package

## 0.3.0 - beta

* Update the plugin versions
* Update example app (now includes how to retrieve the trimmed video)
* Update Readme
* Fixes some memory leak issues

## 0.2.7 - beta

* Add a new property called `maxVideoLength` for specifying the max length of the output video.
* Update Docs

## 0.2.6 - beta

* Add a new property called `fit` to `TrimEditor` widget which will let you specify the image fit type of each thumbnail image.
* Add a new property to `saveTrimmedVideo()` method called `applyVideoEncoding` which will let you specify whether to re-encode the trimmed video. 
  
  **NOTE:** Applying this will take significantly greater amount of time to process the output video.

* Improve Docs

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

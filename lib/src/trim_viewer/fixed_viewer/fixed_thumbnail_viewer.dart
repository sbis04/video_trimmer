import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:video_trimmer/src/utils/trimmer_utils.dart';

class FixedThumbnailViewer extends StatelessWidget {
  /// The video file from which thumbnails are generated.
  final File videoFile;

  /// The total duration of the video in milliseconds.
  final int videoDuration;

  /// The height of each thumbnail. Always maintains 1:1 aspect ratio.
  final double thumbnailHeight;

  /// How the thumbnails should be inscribed into the allocated space.
  final BoxFit fit;

  /// The number of thumbnails to generate.
  final int numberOfThumbnails;

  /// Callback function that is called when thumbnail loading is complete.
  final VoidCallback onThumbnailLoadingComplete;

  /// The quality of the generated thumbnails, ranging from 0 to 100.
  final int quality;

  /// For showing the thumbnails generated from the video,
  /// like a frame by frame preview
  ///
  /// - [videoFile] is the video file from which thumbnails are generated.
  /// - [videoDuration] is the total duration of the video in milliseconds.
  /// - [thumbnailHeight] is the height of each thumbnail. Always maintains 1:1 aspect ratio.
  /// - [numberOfThumbnails] is the number of thumbnails to generate.
  /// - [fit] is how the thumbnails should be inscribed into the allocated space.
  /// - [onThumbnailLoadingComplete] is the callback function that is called when thumbnail loading is complete.
  /// - [quality] is the quality of the generated thumbnails, ranging from 0 to 100. Defaults to 75.
  const FixedThumbnailViewer({
    super.key,
    required this.videoFile,
    required this.videoDuration,
    required this.thumbnailHeight,
    required this.numberOfThumbnails,
    required this.fit,
    required this.onThumbnailLoadingComplete,
    this.quality = 75,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Uint8List?>>(
      stream: generateThumbnail(
        videoPath: videoFile.path,
        videoDuration: videoDuration,
        numberOfThumbnails: numberOfThumbnails,
        thumbnailHeight: thumbnailHeight,
        quality: quality,
        onThumbnailLoadingComplete: onThumbnailLoadingComplete,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Uint8List?> imageBytes = snapshot.data!;
          return Row(
            mainAxisSize: MainAxisSize.max,
            children: List.generate(
              numberOfThumbnails,
              (index) => SizedBox(
                height: thumbnailHeight,
                width: thumbnailHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 0.2,
                      child: Image.memory(
                        imageBytes[0] ?? kTransparentImage,
                        fit: fit,
                      ),
                    ),
                    index < imageBytes.length
                        ? FadeInImage(
                            placeholder: MemoryImage(kTransparentImage),
                            image: MemoryImage(imageBytes[index]!),
                            fit: fit,
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Container(
            color: Colors.grey[900],
            height: thumbnailHeight,
            width: double.maxFinite,
          );
        }
      },
    );
  }
}

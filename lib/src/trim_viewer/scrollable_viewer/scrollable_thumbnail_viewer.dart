import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ScrollableThumbnailViewer extends StatelessWidget {
  final File videoFile;
  final int videoDuration;
  final double thumbnailHeight;
  final BoxFit fit;
  final int numberOfThumbnails;
  final int quality;
  final ScrollController scrollController;
  final VoidCallback onThumbnailLoadingComplete;

  /// For showing the thumbnails generated from the video,
  /// like a frame by frame preview
  const ScrollableThumbnailViewer({
    Key? key,
    required this.videoFile,
    required this.videoDuration,
    required this.thumbnailHeight,
    required this.numberOfThumbnails,
    required this.fit,
    required this.scrollController,
    required this.onThumbnailLoadingComplete,
    this.quality = 75,
  }) : super(key: key);

  Stream<List<Uint8List?>> generateThumbnail() async* {
    final String videoPath = videoFile.path;
    double eachPart = videoDuration / numberOfThumbnails;
    List<Uint8List?> byteList = [];
    // the cache of last thumbnail
    Uint8List? lastBytes;
    for (int i = 1; i <= numberOfThumbnails; i++) {
      Uint8List? bytes;
      try {
        bytes = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: (eachPart * i).toInt(),
          quality: quality,
        );
      } catch (e) {
        debugPrint('ERROR: Couldn\'t generate thumbnails: $e');
      }
      // if current thumbnail is null use the last thumbnail
      if (bytes != null) {
        lastBytes = bytes;
      } else {
        bytes = lastBytes;
      }
      byteList.add(bytes);
      if (byteList.length == numberOfThumbnails) {
        onThumbnailLoadingComplete();
      }
      yield byteList;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: scrollController,
        child: SizedBox(
          width: numberOfThumbnails * thumbnailHeight,
          height: thumbnailHeight,
          child: StreamBuilder<List<Uint8List?>>(
            stream: generateThumbnail(),
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
          ),
        ),
      ),
    );
  }
}

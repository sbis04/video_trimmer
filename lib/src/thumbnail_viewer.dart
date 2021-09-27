import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailViewer extends StatelessWidget {
  final File videoFile;
  final int videoDuration;
  final double thumbnailHeight;
  final BoxFit fit;
  final int numberOfThumbnails;
  final int quality;

  /// For showing the thumbnails generated from the video,
  /// like a frame by frame preview
  const ThumbnailViewer({
    Key? key,
    required this.videoFile,
    required this.videoDuration,
    required this.thumbnailHeight,
    required this.numberOfThumbnails,
    required this.fit,
    this.quality = 75,
  }) : super(key: key);

  Stream<List<Uint8List?>> generateThumbnail() async* {
    final String _videoPath = videoFile.path;

    double _eachPart = videoDuration / numberOfThumbnails;

    List<Uint8List?> _byteList = [];

    // the cache of last thumbnail
    Uint8List? _lastBytes;

    for (int i = 1; i <= numberOfThumbnails; i++) {
      Uint8List? _bytes;
      _bytes = await VideoThumbnail.thumbnailData(
        video: _videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: (_eachPart * i).toInt(),
        quality: quality,
      );

      // if current thumbnail is null use the last thumbnail
      if (_bytes != null) {
        _lastBytes = _bytes;
      } else {
        _bytes = _lastBytes;
      }

      _byteList.add(_bytes);

      yield _byteList;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Uint8List?>>(
      stream: generateThumbnail(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Uint8List?> _imageBytes = snapshot.data!;
          return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageBytes.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: thumbnailHeight,
                  width: thumbnailHeight,
                  child: Image(
                    image: MemoryImage(_imageBytes[index]!),
                    fit: fit,
                  ),
                );
              });
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

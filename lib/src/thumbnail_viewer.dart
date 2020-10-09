import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailViewer extends StatelessWidget {
  final videoFile;
  final videoDuration;
  final thumbnailHeight;
  final fit;
  final int numberOfThumbnails;
  final int quality;

  /// For showing the thumbnails generated from the video,
  /// like a frame by frame preview
  ThumbnailViewer({
    @required this.videoFile,
    @required this.videoDuration,
    @required this.thumbnailHeight,
    @required this.numberOfThumbnails,
    @required this.fit,
    this.quality = 75,
  })  : assert(videoFile != null),
        assert(videoDuration != null),
        assert(thumbnailHeight != null),
        assert(numberOfThumbnails != null),
        assert(quality != null);

  Stream<List<Uint8List>> generateThumbnail() async* {
    final String _videoPath = videoFile.path;

    double _eachPart = videoDuration / numberOfThumbnails;

    List<Uint8List> _byteList = [];

    for (int i = 1; i <= numberOfThumbnails; i++) {
      Uint8List _bytes;
      _bytes = await VideoThumbnail.thumbnailData(
        video: _videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: (_eachPart * i).toInt(),
        quality: quality,
      );

      _byteList.add(_bytes);

      yield _byteList;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: generateThumbnail(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Uint8List> _imageBytes = snapshot.data;
          return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                return Container(
                  height: thumbnailHeight,
                  width: thumbnailHeight,
                  child: Image(
                    image: MemoryImage(_imageBytes[index]),
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

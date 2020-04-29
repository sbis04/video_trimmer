import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/trim_editor.dart';

class VideoViewer extends StatefulWidget {
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;
  VideoViewer({
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
    this.padding = const EdgeInsets.all(0.0),
  });

  @override
  _VideoViewerState createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: widget.padding,
        child: AspectRatio(
          aspectRatio: videoPlayerController.value.aspectRatio,
          child: videoPlayerController.value.initialized
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: widget.borderWidth,
                      color: widget.borderColor,
                    ),
                  ),
                  child: VideoPlayer(videoPlayerController),
                )
              : Container(
                  child: Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

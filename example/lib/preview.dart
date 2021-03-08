import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class Preview extends StatefulWidget {
  final String outputVideoPath;

  Preview(this.outputVideoPath);

  @override
  _PreviewState createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.file(File(widget.outputVideoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Preview"),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: _controller.value.isInitialized
              ? Container(
                  child: VideoPlayer(_controller),
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:appinio_video_player/appinio_video_player.dart';

class Preview extends StatefulWidget {
  const Preview({super.key, required this.path});
  static const route = '/VideoMessage';
  final String? path;

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  File? pa;
  late VideoPlayerController videoPlayerControll;
  late CustomVideoPlayerController _customVideoPlayerController;
  @override
  void initState() {
    super.initState();
    videoPlayerControll = VideoPlayerController.file(File(widget.path!))
      ..initialize().then((value) {
        setState(() {});
      });
    _customVideoPlayerController = CustomVideoPlayerController(
      context: context,
      videoPlayerController: videoPlayerControll,
    );
  }

  @override
  void dispose() {
    _customVideoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomVideoPlayer(
              customVideoPlayerController: _customVideoPlayerController),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

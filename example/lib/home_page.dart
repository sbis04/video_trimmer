import 'dart:io';

import 'package:example/trimmer_view.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_trimmer/video_trimmer.dart';

class HomePage extends StatelessWidget {
  final Trimmer _trimmer = Trimmer();
  final ImagePicker imagePicker = ImagePicker();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Trimmer"),
      ),
      body: Center(
        child: Container(
          child: RaisedButton(
            child: Text("LOAD VIDEO"),
            onPressed: () async {
              PickedFile file = await imagePicker.getVideo(
                source: ImageSource.gallery,
              );
              if (file != null) {
                await _trimmer.loadVideo(videoFile: File(file.path));
                Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                  return TrimmerView(_trimmer);
                }));
              }
            },
          ),
        ),
      ),
    );
  }
}

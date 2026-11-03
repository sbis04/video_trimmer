import 'package:flutter/material.dart';

import 'pages/home_page.dart';

void main() => runApp(const VideoTrimmerExample());

class VideoTrimmerExample extends StatelessWidget {
  const VideoTrimmerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Trimmer',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF9A825),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        sliderTheme: const SliderThemeData(
          trackHeight: 2,
          overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
        ),
      ),
      home: const HomePage(),
    );
  }
}

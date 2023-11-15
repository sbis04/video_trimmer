import 'package:example/core/constants.dart';
import 'package:flutter/material.dart';

class LoadingScreen {
  final GlobalKey globalKey;

  LoadingScreen(this.globalKey);

  show([String? text]) {
    if (globalKey.currentContext == null) return;

    showDialog<String>(
      context: globalKey.currentContext!,
      builder: (BuildContext context) {
        return Material(
          color: Colors.transparent,
          child: WillPopScope(
            onWillPop: () => Future.value(false),
            child: const Center(
              child: SizedBox(
                height: 80,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 75,
                        height: 75,
                        child: CircularProgressIndicator(
                          semanticsLabel: 'Linear progress indicator',
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        width: 65,
                        height: 65,
                        child: CircleAvatar(
                          backgroundImage: AssetImage(
                            'assets/tf_icon.png',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  hide() {
    if (globalKey.currentContext == null) return;

    Navigator.pop(globalKey.currentContext!);
  }
}

@protected
final scaffoldGlobalKey = GlobalKey<ScaffoldState>();

@protected
var loadingScreen = LoadingScreen(scaffoldGlobalKey);

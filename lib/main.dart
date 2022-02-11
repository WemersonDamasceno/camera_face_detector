// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:screenshot/screenshot.dart';

import 'face_detector_page.dart';

List<CameraDescription> cameras = [];
CameraController cameraControllerGlobal = CameraController(
  cameras[1],
  ResolutionPreset.low,
  enableAudio: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ScreenshotController screenshotController = ScreenshotController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Process'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    tileColor: Theme.of(context).primaryColor,
                    title: const Text(
                      'Face Detector',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FaceDetectorView()));
                    },
                  ),
                  //Area pra tirar o print
                  Screenshot(
                    controller: screenshotController,
                    child: Container(
                        padding: const EdgeInsets.all(30.0),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.blueAccent, width: 5.0),
                          color: Colors.amberAccent,
                        ),
                        child: const Text(
                            "This widget will be captured as an image")),
                  ),
                  ElevatedButton(
                    child: const Text(
                      'Capture Above Widget',
                    ),
                    onPressed: () {
                      screenshotController
                          .capture(delay: const Duration(milliseconds: 10))
                          .then((capturedImage) async {
                        showCapturedWidget(context, capturedImage!);
                      }).catchError((onError) {
                        print(onError);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> showCapturedWidget(
      BuildContext context, Uint8List capturedImage) {
    return showDialog(
      useSafeArea: false,
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text("Captured widget screenshot"),
        ),
        body: Center(
            child: capturedImage != null
                ? Image.memory(capturedImage)
                : Container()),
      ),
    );
  }

  // _saved(File image) async {
  //   // final result = await ImageGallerySaver.save(image.readAsBytesSync());
  //   print("File Saved to Gallery");
  // }

}

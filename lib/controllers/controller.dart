import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ControllerCamera {
  static ControllerCamera instance = ControllerCamera();
  late CameraController controller;
  bool isInited = false;

  Future<void> iniciarControllerCamera() async {
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      final cameras = await availableCameras();
      controller = CameraController(cameras[1], ResolutionPreset.medium);
    });
  }

  Future<String> takePicture() async {
    String url = "";
    join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');
    await controller.takePicture().then((res) => {url = res.path});
    return url;
  }

  Future<void> startImage(processCameraImage) async {
    await controller.startImageStream(processCameraImage);
  }
}

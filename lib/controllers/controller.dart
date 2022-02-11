import 'package:camera/camera.dart';

import '../main.dart';

class ControllerCamera {
  static ControllerCamera instance = ControllerCamera();
  final CameraController controller = CameraController(
    cameras[1],
    ResolutionPreset.low,
    enableAudio: false,
  );
}

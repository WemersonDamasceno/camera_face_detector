import 'package:camera/camera.dart';
import 'package:camera_process/camera_process.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'main.dart';

CameraController? _controller;

class CameraView extends StatefulWidget {
  const CameraView({
    Key? key,
    required this.customPaint,
    required this.onImage,
    this.initialDirection = CameraLensDirection.front,
    required this.buttonWidget,
    required this.getFrase,
    required this.getPosicao,
  }) : super(key: key);

  final CustomPaint? customPaint;
  final Widget buttonWidget;
  final String getFrase;
  final int getPosicao;
  final Function(InputImage inputImage, CameraImage img) onImage;
  final CameraLensDirection initialDirection;

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final int _cameraIndex = 1;

  @override
  void initState() {
    super.initState();
    _startLiveFeed();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161616),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _liveFeedBody(),
    );
  }

  Widget _liveFeedBody() {
    var posicao = widget.getPosicao;
    if (_controller?.value.isInitialized == false) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: SizedBox(
              height: 320,
              width: 400,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(400),
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(400)),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: CameraPreview(_controller!),
                          ),
                        ),
                      ),
                      widget.getPosicao == 0 || widget.getPosicao == 4
                          ? Container()
                          : widget.getPosicao == 1
                              ? Positioned(
                                  top: 110,
                                  left: 190,
                                  child: RotatedBox(
                                    quarterTurns: 0,
                                    child: Image.asset(
                                      "assets/gif_seta.gif",
                                      height: 80,
                                      width: 180,
                                      color: Colors.purple,
                                    ),
                                  ),
                                )
                              : widget.getPosicao == 3
                                  ? Positioned(
                                      top: 110,
                                      right: 190,
                                      child: RotatedBox(
                                        quarterTurns: 2,
                                        child: Image.asset(
                                          "assets/gif_seta.gif",
                                          height: 80,
                                          width: 180,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    )
                                  : Container(),
                    ],
                  ),
                  if (widget.customPaint != null) widget.customPaint!,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              widget.getFrase,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: widget.buttonWidget,
          ),
        ],
      ),
    );
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationMethods.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.Rotation_0deg;

    final inputImageFormat =
        InputImageFormatMethods.fromRawValue(image.format.raw) ??
            InputImageFormat.NV21;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    widget.onImage(inputImage, image);
  }
}

// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camera_process/camera_process.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'main.dart';

int proximaFoto = 0;
bool isFotoEsquerda = false;
bool isFotoDireita = false;
bool isFotoFrente = false;

//Camera View
CameraController? _controller;
var bytesImagemFrente;
var bytesImagemEsquerda;
var bytesImagemDireita;

const int nFRENTE = 1;
const int nESQUERDA = 2;
const int nDIREITA = 3;
const int nFINAL = 4;

class FaceDetectorView extends StatefulWidget {
  const FaceDetectorView({Key? key}) : super(key: key);

  @override
  _FaceDetectorViewState createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  FaceDetector faceDetector =
      CameraProcess.vision.faceDetector(const FaceDetectorOptions(
    enableContours: true,
    enableClassification: true,
  ));
  bool isBusy = false;
  CustomPaint? customPaint;

  /*Camera View*/
  //CAMERA TRASEIRA É 0
  //CAMERA FRONTAL É 1
  final int _cameraIndex = 1;
  /*Camera View*/

  @override
  void initState() {
    super.initState();
    _startLiveFeed();
  }

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
    );
    await _controller?.initialize();

    _controller?.startImageStream(_processCameraImage);
    setState(() {});
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

    processImage(inputImage);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CameraPreview(_controller!),
          if (customPaint != null) customPaint!,
        ],
      ),
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    final faces = await faceDetector.processImage(inputImage);

    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
          faces,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      customPaint = CustomPaint(painter: painter);
    } else {
      customPaint = null;
    }
    isBusy = false;
    if (mounted) {
      setState(() {});
    }

    //Todas as fotas foram tiradas
    if (isFotoDireita && isFotoEsquerda && isFotoFrente) {
      print("Todas as fotos já foram tiradas");
      await _controller!.stopImageStream(); //Remover depois
    }
    //Não?
    else {
      takeAPicture(proximaFoto, inputImage);
    }
  }

  //Tirar a foto
  void takeAPicture(int lado, InputImage inputImage) {
    if (lado == nFRENTE) {
      setState(() {
        isFotoFrente = true;
        bytesImagemFrente = inputImage.bytes;
        proximaFoto = 0;
        print("FRENTE caminho da imagem: $bytesImagemFrente");
        print("FRENTE caminho da imagem: $bytesImagemFrente");
      });
    } else if (lado == nESQUERDA) {
      setState(() async {
        isFotoEsquerda = true;
        bytesImagemEsquerda = inputImage.bytes;
        proximaFoto = 0;
        print("ESQUERDA caminho da imagem: $bytesImagemEsquerda");
        print("ESQUERDA caminho da imagem: $bytesImagemEsquerda");
      });
    } else if (lado == nDIREITA) {
      setState(() {
        isFotoDireita = true;
        bytesImagemDireita = inputImage.bytes;
        proximaFoto = nFINAL;
        print("DIREITA caminho da imagem: $bytesImagemDireita");
        print("DIREITA caminho da imagem: $bytesImagemDireita");
      });
    }
  }
}

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.faces, this.absoluteImageSize, this.rotation);

  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.purple;

    for (final Face face in faces) {
      //Desenhar o retangulo
      canvas.drawRect(
        Rect.fromLTRB(
          translateX(face.boundingBox.left, rotation, size, absoluteImageSize),
          translateY(face.boundingBox.top, rotation, size, absoluteImageSize),
          translateX(face.boundingBox.right, rotation, size, absoluteImageSize),
          translateY(
              face.boundingBox.bottom, rotation, size, absoluteImageSize),
        ),
        paint,
      );

      void paintContour(FaceContourType type) async {
        final faceContour = face.getContour(type);
        for (Offset point in faceContour!.positionsList) {
          //Se o nariz for pro canto direito
          if (type == FaceContourType.noseBottom) {
            //Tirar primeiro foto da frente
            if (point.dx < 130 && point.dx > 95) {
              if (isFotoFrente == false) {
                proximaFoto = nFRENTE;
              }
            }
            //Tirar foto da direita
            else if (point.dx < 80) {
              if (isFotoDireita == false &&
                  isFotoEsquerda == false &&
                  isFotoFrente == true) {
                proximaFoto = nDIREITA;
              }
            } else if (point.dx > 150) {
              if (isFotoEsquerda == false &&
                  isFotoDireita == true &&
                  isFotoFrente == true) {
                proximaFoto = nESQUERDA;
              }
            }
          }
        }
      }

      paintContour(FaceContourType.noseBottom);
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.faces != faces;
  }
}

double translateX(
    double x, InputImageRotation rotation, Size size, Size absoluteImageSize) {
  switch (rotation) {
    case InputImageRotation.Rotation_90deg:
      return x *
          size.width /
          (Platform.isIOS ? absoluteImageSize.width : absoluteImageSize.height);
    case InputImageRotation.Rotation_270deg:
      return size.width -
          x *
              size.width /
              (Platform.isIOS
                  ? absoluteImageSize.width
                  : absoluteImageSize.height);
    default:
      return x * size.width / absoluteImageSize.width;
  }
}

double translateY(
    double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
  switch (rotation) {
    case InputImageRotation.Rotation_90deg:
    case InputImageRotation.Rotation_270deg:
      return y *
          size.height /
          (Platform.isIOS ? absoluteImageSize.height : absoluteImageSize.width);
    default:
      return y * size.height / absoluteImageSize.height;
  }
}

// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camera_process/camera_process.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'camera_view.dart';
import 'package:image/image.dart' as imglib;

int qtdFoto = 0;
bool isFotoEsquerda = false;
bool isFotoDireita = false;
bool isFotoFrente = false;

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

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Face Detector',
      customPaint: customPaint,
      onImage: (inputImage, image) {
        processImage(inputImage, image);
      },
      initialDirection: CameraLensDirection.front,
    );
  }

  Future<void> processImage(InputImage inputImage, CameraImage cimg) async {
    if (isBusy) return;
    isBusy = true;
    final faces = await faceDetector.processImage(inputImage);
    // final CameraController? cameraController = controller;
    CameraController controller;
    List<CameraDescription> cameras = [];

    print(inputImage.filePath);

    //WidgetsFlutterBinding.ensureInitialized();
    //cameras = await availableCameras();
    print(inputImage.inputImageData?.inputImageFormat);

    print(inputImage.inputImageData);
    //controller = CameraController(cameras[1], ResolutionPreset.max);
    if (qtdFoto == 0) {
      //controller.takePicture();

      String img = await convertYUV420toImageColor(cimg);

      Uint8List imgbytes = inputImage.bytes!;
      //Salvar arquivo temporario

      Directory appDocDir = await getApplicationDocumentsDirectory();

      final tempFile =
          File(path.join(appDocDir.path, 'picture_${DateTime.now()}.jpg'));
      await tempFile.writeAsBytes(imgbytes);
      if (await tempFile.exists()) {
        Image i = Image.file(File(tempFile.path));
        print('existe');
      }
      print("Path da imagem: ${tempFile.path}");
    }

    if (faces.length > 1) {
      const snackBar = SnackBar(
        content: Text('Existe mais de uma pessoa na frente da camera!'),
      );
      // ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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
  }
}

const shift = (0xFF << 24);
Future<String> convertYUV420toImageColor(CameraImage image) async {
  var documentDirectory = await getExternalStorageDirectory();
  try {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;
    print("uvRowStride: " + uvRowStride.toString());
    print("uvPixelStride: " + uvPixelStride.toString());
    var img = imglib.Image(width, height); // Create Image buffer
    // Fill image buffer with plane[0] from YUV420_888
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride! * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        img.data[index] = (0xFF << 24) | (b << 16) | (g << 8) | r;
      }
    }
    imglib.PngEncoder pngEncoder = imglib.PngEncoder(level: 0, filter: 0);
    List<int> png = pngEncoder.encodeImage(img);
    var originalImage = imglib.decodeImage(png);
    final height1 = originalImage?.height ?? 1;
    final width1 = originalImage?.width ?? 1;
    imglib.Image fixedImage;
    if (height1 < width1) {
      originalImage = imglib.copyRotate(originalImage!, 270);
    }
    var ph = await getExternalStorageDirectory();
    String? p = ph?.path;
    final path = join(p!, "teste.jpg");
    print(path);
    File(path).writeAsBytesSync(imglib.encodeJpg(originalImage!));
    return path;
  } catch (e) {
    print(">>>>>>>>>>>> ERROR:" + e.toString());
  }
  Image i = Image.asset(
    'images/lake.jpg',
    width: 600.0,
    height: 240.0,
    fit: BoxFit.cover,
  );
  return '';
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
            //Quando virar o rosto pra direita ou pra esquerda
            if (qtdFoto == 0) {
              if (point.dx < 80) {
                //qtdFoto = 1;
                print("Moveu para a direita: $point");
                print("QTD: $qtdFoto");
              } else if (point.dx > 150) {
                print("Moveu para a esquerda: $point");
                //qtdFoto = 1;
                print("QTD: $qtdFoto");
                //imagem = await _controller?.takePicture();
              }
            }
          }
          //Pintar os pontos

          // canvas.drawCircle(
          //     Offset(
          //       translateX(point.dx, rotation, size, absoluteImageSize),
          //       translateY(point.dy, rotation, size, absoluteImageSize),
          //     ),
          //     1,
          //     paint);
        }
      }

      paintContour(FaceContourType.noseBottom);

      //paintContour(FaceContourType.face);
      // paintContour(FaceContourType.leftEyebrowTop);
      // paintContour(FaceContourType.leftEyebrowBottom);
      // paintContour(FaceContourType.rightEyebrowTop);
      // paintContour(FaceContourType.rightEyebrowBottom);
      // paintContour(FaceContourType.leftEye);
      // paintContour(FaceContourType.rightEye);
      // paintContour(FaceContourType.upperLipTop);
      // paintContour(FaceContourType.upperLipBottom);
      // paintContour(FaceContourType.lowerLipTop);
      // paintContour(FaceContourType.lowerLipBottom);
      // paintContour(FaceContourType.noseBridge);
      // paintContour(FaceContourType.leftCheek);
      // paintContour(FaceContourType.rightCheek);
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

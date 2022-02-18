import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camera_process/camera_process.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as imglib;

import 'camera_view.dart';

int nNextPhoto = 0;
bool isPhotoLeft = false;
bool isPhotoRight = false;
bool isPhotoFront = false;
bool isStartTakePhotos = false;

const int nSTART = 0;
const int nFRONT = 1;
const int nLEFT = 2;
const int nRIGHT = 3;
const int nEND = 4;

String getFraseInstrucao = "Procure um local iluminado e clique em iniciar.";

class FaceDetectorView extends StatefulWidget {
  const FaceDetectorView({Key? key}) : super(key: key);

  @override
  _FaceDetectorViewState createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  FaceDetector faceDetector = CameraProcess.vision.faceDetector(
    const FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );
  bool isBusy = false;
  CustomPaint? customPaint;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return CameraView(
      getPosicao: nNextPhoto,
      getFrase: getFraseInstrucao,
      buttonWidget: buttonWidget(),
      customPaint: customPaint,
      onImage: (inputImage, image) {
        processImage(inputImage, image);
      },
      initialDirection: CameraLensDirection.front,
    );
  }

  Widget buttonWidget() {
    return nNextPhoto == nSTART || nNextPhoto == nEND
        ? ElevatedButton(
            onPressed: () {
              if (nNextPhoto == nSTART) {
                setState(() {
                  isStartTakePhotos = true;
                  getFraseInstrucao =
                      "Mantenha sua cabeça no centro do circulo.";
                  nNextPhoto = nFRONT;
                });
              } else if (nNextPhoto == nEND) {
                setState(() {
                  getFraseInstrucao =
                      "Parabéns você finalizou seu reconhecimento facial.";
                });
                //Enviar pra proxima tela
              }
            },
            child: Text(
              nNextPhoto == nSTART ? "Iniciar" : "Continuar",
              style: const TextStyle(fontSize: 17),
            ),
          )
        : Container();
  }

  Future<void> processImage(
    InputImage inputImage,
    CameraImage cameraImage,
  ) async {
    if (isBusy) return;
    isBusy = true;
    final faces = await faceDetector.processImage(inputImage);

    //Se tiver mais de uma pessoa na frente da camera
    if (faces.length > 1) {
      const snackBar = SnackBar(
        content: Text('Existe mais de uma pessoa na frente da camera!'),
      );
      ScaffoldMessenger.of(this.context).showSnackBar(snackBar);
    } else {
      if (isStartTakePhotos) {
        //Todas as fotas foram tiradas
        if (isPhotoRight && isPhotoLeft && isPhotoFront) {
          nNextPhoto = nEND;
          print("Todas as fotos já foram tiradas");
          //Enviar pra api
        }
        //Não?
        else {
          await takeAPicture(inputImage, cameraImage);
        }
      }
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

  //Tirar a foto
  Future<void> takeAPicture(
    InputImage inputImage,
    CameraImage cameraImage,
  ) async {
    if (nNextPhoto == nFRONT && !isPhotoFront) {
      setState(() {
        isPhotoFront = true;
        getFraseInstrucao = "Mova sua cabeça lentamente para o lado direito.";
      });
      File fotoFrente = await salvarFoto("frente", cameraImage, inputImage);
    } else if (nNextPhoto == nRIGHT && !isPhotoRight) {
      setState(() {
        getFraseInstrucao = "Mova sua cabeça lentamente para o lado esquerdo.";
        isPhotoRight = true;
      });
      File fotoDireita = await salvarFoto("direita", cameraImage, inputImage);
    } else if (nNextPhoto == nLEFT && !isPhotoLeft) {
      setState(() {
        getFraseInstrucao =
            "Parabéns você finalizou seu reconhecimento facial.";
        isPhotoLeft = true;
      });
      File fotoEsquerda = await salvarFoto("esquerda", cameraImage, inputImage);
    }
  }

  Future<File> salvarFoto(
    String lado,
    CameraImage cimg,
    InputImage inputImage,
  ) async {
    await convertYUV420toImageColor(cimg, lado);
    Uint8List imgbytes = inputImage.bytes!;
    Directory appDocDir = await getApplicationDocumentsDirectory();
    final tempFile =
        File(path.join(appDocDir.path, 'picture_${DateTime.now()}.jpg'));
    await tempFile.writeAsBytes(imgbytes);
    if (await tempFile.exists()) {
      Image i = Image.file(File(tempFile.path));
      print('EXISTE, PATH: $i');
    }
    return tempFile;
  }
}

const shift = (0xFF << 24);
Future<String> convertYUV420toImageColor(
    CameraImage image, String nomeImagem) async {
  //var documentDirectory = await getExternalStorageDirectory();
  try {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;
    // print("uvRowStride: " + uvRowStride.toString());
    // print("uvPixelStride: " + uvPixelStride.toString());
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
    //imglib.Image fixedImage;
    if (height1 < width1) {
      originalImage = imglib.copyRotate(originalImage!, 270);
    }
    var ph = await getExternalStorageDirectory();
    String? p = ph?.path;
    final path = join(p!, "$nomeImagem.jpg");
    //print(path);
    File(path).writeAsBytesSync(imglib.encodeJpg(originalImage!));
    return path;
  } catch (e) {
    print(">>>>>>>>>>>> ERROR:" + e.toString());
  }
  // Image i = Image.asset(
  //   'images/lake.jpg',
  //   width: 600.0,
  //   height: 240.0,
  //   fit: BoxFit.cover,
  // );
  return '';
}

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.faces, this.absoluteImageSize, this.rotation);

  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  @override
  void paint(Canvas canvas, Size size) {
    // final Paint paint = Paint()
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 2
    //   ..color = Colors.transparent;

    for (final Face face in faces) {
      //Desenhar o retangulo
      // canvas.drawRect(
      //   Rect.fromLTRB(
      //     translateX(face.boundingBox.left, rotation, size, absoluteImageSize),
      //     translateY(face.boundingBox.top, rotation, size, absoluteImageSize),
      //     translateX(face.boundingBox.right, rotation, size, absoluteImageSize),
      //     translateY(
      //         face.boundingBox.bottom, rotation, size, absoluteImageSize),
      //   ),
      //   paint,
      // );

      void paintContour(FaceContourType type) async {
        final faceContour = face.getContour(type);
        for (Offset point in faceContour!.positionsList) {
          //Se o nariz for pro canto direito

          if (type == FaceContourType.noseBottom) {
            //Tirar primeiro foto da frente
            if (point.dx < 130 && point.dx > 95) {
              if (isPhotoFront == false) {
                if (isStartTakePhotos) {
                  nNextPhoto = nFRONT;
                }
              }
            }
            //Tirar foto da direita
            else if (point.dx < 80) {
              if (isPhotoRight == false &&
                  isPhotoLeft == false &&
                  isPhotoFront == true) {
                nNextPhoto = nRIGHT;
              }
            } else if (point.dx > 150) {
              if (isPhotoLeft == false &&
                  isPhotoRight == true &&
                  isPhotoFront == true) {
                nNextPhoto = nLEFT;
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

// double translateX(
//     double x, InputImageRotation rotation, Size size, Size absoluteImageSize) {
//   switch (rotation) {
//     case InputImageRotation.Rotation_90deg:
//       return x *
//           size.width /
//           (Platform.isIOS ? absoluteImageSize.width : absoluteImageSize.height);
//     case InputImageRotation.Rotation_270deg:
//       return size.width -
//           x *
//               size.width /
//               (Platform.isIOS
//                   ? absoluteImageSize.width
//                   : absoluteImageSize.height);
//     default:
//       return x * size.width / absoluteImageSize.width;
//   }
// }

// double translateY(
//     double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
//   switch (rotation) {
//     case InputImageRotation.Rotation_90deg:
//     case InputImageRotation.Rotation_270deg:
//       return y *
//           size.height /
//           (Platform.isIOS ? absoluteImageSize.height : absoluteImageSize.width);
//     default:
//       return y * size.height / absoluteImageSize.height;
//   }
// }

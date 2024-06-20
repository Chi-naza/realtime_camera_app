import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjDetectionCameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const ObjDetectionCameraScreen({super.key, required this.cameras});
  @override
  State<ObjDetectionCameraScreen> createState() =>
      _ObjDetectionCameraScreenState();
}

class _ObjDetectionCameraScreenState extends State<ObjDetectionCameraScreen> {
  late List<CameraDescription> _cameras;

  late CameraController controller;
  CameraImage? img;

  bool isBusy = false;

  //declare Obj Detector
  late ObjectDetector objectDetector;

  dynamic scanResults;

  @override
  void initState() {
    super.initState();

    _cameras = widget.cameras;

    // Options to configure the detector while using with base model.
    // Base Model is the default obj detection model provided by Google mlkit
    // we can decide to use or custom model but we are limiting this example to the default model.
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );

    objectDetector = ObjectDetector(options: options);

    //initialize the camera controller
    controller = CameraController(_cameras[0], ResolutionPreset.max);

    // initialize camera on the device and start streaming
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) {
        if (!isBusy) {
          isBusy = true;
          img = image;
          doObjectDetectionOnFrame(image);
        }
      });
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            debugPrint('User denied camera access.');
            break;
          default:
            debugPrint('Handle other errors.');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return !controller.value.isInitialized
        ? Container()
        : Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0.0,
                left: 0.0,
                width: size.width,
                height: size.height,
                child: CameraPreview(controller),
              ),
              Positioned(
                top: 0.0,
                left: 0.0,
                width: size.width,
                height: size.height,
                child: buildObjectCameraBody(),
              ),
            ],
          );
  }

  // Handle Realtime Object Detection
  Future<void> doObjectDetectionOnFrame(CameraImage camImage) async {
    InputImage? frameImage = _inputImageFromCameraImage(camImage);

    List<DetectedObject> detectedObjs =
        await objectDetector.processImage(frameImage!);

    debugPrint("NUMBER OF OBJECTS: ${detectedObjs.length}");

    setState(() {
      scanResults = detectedObjs;
      isBusy = false;
    });
  }

  // converting image frames picked from the footage to InputImage
  // which will conform to the Google ML-Kit Image labeller
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
    final camera = _cameras[0];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // Conversion // to Uint8List data
    // This is because, the inputImageFormatValue returned does not conform
    // to nv21 format.
    final concatenated = Uint8List.fromList(
      [
        ...image.planes[0].bytes,
        ...image.planes[1].bytes,
        ...image.planes[2].bytes,
      ],
    );

    // Getting bytesPerRow from the image plane
    final plane = image.planes.first;
    debugPrint("IMAGE PLANES: ${image.planes}");
    debugPrint("PLANE: $plane");

    // Create an inPutImage obj from Bytes
    InputImage inputImage = InputImage.fromBytes(
      bytes: concatenated,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: InputImageFormatValue.fromRawValue(35)!, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );

    debugPrint("INPUT IMAGE FROM CONVERTED>>:::: $inputImage");

    return inputImage;
  }

  // The body widget of the object detector view
  Widget buildObjectCameraBody() {
    if (scanResults == null || !controller.value.isInitialized) {
      return Container();
    }

    final Size imageSize = Size(
      controller.value.previewSize!.width,
      controller.value.previewSize!.height,
    );

    CustomPainter painter = ObjectDetectorPainter(
      detectedObjects: scanResults,
      currentImageSize: imageSize,
    );

    return CustomPaint(painter: painter);
  }
}

class ObjectDetectorPainter extends CustomPainter {
  final List<DetectedObject> detectedObjects;
  final Size currentImageSize;
  ObjectDetectorPainter(
      {required this.detectedObjects, required this.currentImageSize});

  @override
  void paint(Canvas canvas, Size size) {
    double scaleY = size.height / currentImageSize.height;
    double scaleX = size.width / currentImageSize.width;

    Paint paint = Paint();
    paint.color = Colors.pinkAccent;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;

    for (DetectedObject detObj in detectedObjects) {
      canvas.drawRect(
        Rect.fromLTRB(
          detObj.boundingBox.left * scaleX,
          detObj.boundingBox.top * scaleY,
          detObj.boundingBox.right * scaleX,
          detObj.boundingBox.bottom * scaleY,
        ),
        paint,
      );

      var list = detObj.labels;

      for (Label label in list) {
        debugPrint("${label.text}   ${label.confidence.toStringAsFixed(2)}");
        TextSpan span = TextSpan(
            text: label.text,
            style: const TextStyle(fontSize: 25, color: Colors.blue));
        TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(
            canvas,
            Offset(detObj.boundingBox.left * scaleX,
                detObj.boundingBox.top * scaleY));
        break;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

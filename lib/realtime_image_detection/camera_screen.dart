import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> _cameras;

  late CameraController controller;
  CameraImage? img;
  bool isBusy = false;
  String result = "Result to be shown soon. . .";

  //declare ImageLabeler
  late ImageLabeler imageLabeler;

  @override
  void initState() {
    super.initState();

    _cameras = widget.cameras;

    //initialize labeler options
    final ImageLabelerOptions options =
        ImageLabelerOptions(confidenceThreshold: 0.5);

    // initialize the image labeler
    imageLabeler = ImageLabeler(options: options);

    //initialize the camera controller
    controller = CameraController(_cameras[0], ResolutionPreset.max);

    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) {
        if (!isBusy) {
          isBusy = true;
          img = image;
          doImageLabeling();
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
    return !controller.value.isInitialized
        ? Container()
        : Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              Container(
                margin: const EdgeInsets.only(left: 10, bottom: 10),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    result,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              )
            ],
          );
  }

// Handle Realtime image Labelling
  Future<void> doImageLabeling() async {
    result = "";

    InputImage? inputtImage = _inputImageFromCameraImage(img!);

    final List<ImageLabel> labels =
        await imageLabeler.processImage(inputtImage!);

    for (ImageLabel label in labels) {
      final String text = label.label;
      final int index = label.index;
      final double confidence = label.confidence;

      result = "Object: $text, Accuracy: ${confidence.toStringAsFixed(2)}\n";
      debugPrint("RESULT: $result");
    }

    setState(() {
      result;
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
}

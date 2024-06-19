import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realtime_camera_app/widgets/text_n_value_widget.dart';

import 'dart:ui' as ui;

class CustomModelObjectDetectionScreen extends StatefulWidget {
  const CustomModelObjectDetectionScreen({super.key});

  @override
  State<CustomModelObjectDetectionScreen> createState() =>
      _CustomModelObjectDetectionScreenState();
}

class _CustomModelObjectDetectionScreenState
    extends State<CustomModelObjectDetectionScreen> {
  File? _image;
  late ImagePicker imagePicker;

  String resultName = "";
  String resultConfidence = "0.0";

  late ObjectDetector objectDetector;

  List<DetectedObject> detectedObjects = [];

  // decoded image
  var decodedImage;
  int imgWidth = 0;
  int imgHeight = 0;

  @override
  void initState() {
    // init image picker
    imagePicker = ImagePicker();

    // Options to configure the detector while using with base model.
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );

    objectDetector = ObjectDetector(options: options);

    // call super
    super.initState();
  }

  @override
  void dispose() {
    objectDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Object Detection",
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.bold,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 43),
              _image == null
                  ? Card(
                      color: Colors.grey,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.45,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              image: const DecorationImage(
                                  image: AssetImage("assets/images/imgno.png"),
                                  fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 13),
                          const TextAndValueWidget(
                            title: 'Image',
                            value: "No Image Details To Display",
                            textColor: Colors.black,
                          ),
                          const SizedBox(height: 13),
                        ],
                      ),
                    )
                  : Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              // image: DecorationImage(
                              //   image: FileImage(_image!),
                              //   fit: BoxFit.cover,
                              // ),
                            ),
                            child: FittedBox(
                              child: SizedBox(
                                width: imgWidth.toDouble(),
                                height: imgHeight.toDouble(),
                                child: CustomPaint(
                                  painter: ObjectPainter(
                                    objectList: detectedObjects,
                                    imageFile: decodedImage,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextAndValueWidget(
                                title: 'Name',
                                value: resultName,
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.15),
                              TextAndValueWidget(
                                title: 'Accuracy',
                                value:
                                    "%${double.parse(resultConfidence) * 100}",
                                textColor: Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          TextAndValueWidget(
                            title: 'Image',
                            value: _image!.path,
                            textColor: Colors.black38,
                          ),
                          const SizedBox(height: 13),
                        ],
                      ),
                    ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: pickAnImage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: const Text('Choose An Image From Gallery'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => pickAnImage(fromCamera: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: const Text('Use The Camera Instead'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // pick image func
  Future<void> pickAnImage({bool fromCamera = false}) async {
    XFile? image;

    if (fromCamera) {
      image = await imagePicker.pickImage(source: ImageSource.camera);
    } else {
      image = await imagePicker.pickImage(source: ImageSource.gallery);
    }

    if (image != null) {
      setState(() {
        _image = File(image!.path);
      });
      doObjectDetection(_image!);
    }
  }

  Future<void> doObjectDetection(File image) async {
    InputImage inputImage = InputImage.fromFile(image);

    detectedObjects = await objectDetector.processImage(inputImage);

    for (DetectedObject detectedObject in detectedObjects) {
      final rect = detectedObject.boundingBox;
      final trackingId = detectedObject.trackingId;

      debugPrint('RECT: $rect, TRACKING_ID: $trackingId');

      for (Label label in detectedObject.labels) {
        debugPrint('OBJECT: ${label.text}, ACCURACY: ${label.confidence}');

        resultName = label.text;
        resultConfidence = label.confidence.toStringAsFixed(2);
      }
    }

    setState(() {});

    drawRectanglesAroundObj();
  }

  // draw rectangles
  Future<void> drawRectanglesAroundObj() async {
    var byteImg = _image!.readAsBytesSync();

    ui.Image deImage = await decodeImageFromList(byteImg);

    imgWidth = deImage.width;
    imgHeight = deImage.height;
    decodedImage = deImage;

    setState(() {});
  }
}

// Customized painter class
class ObjectPainter extends CustomPainter {
  List<DetectedObject> objectList;
  dynamic imageFile;
  ObjectPainter({required this.objectList, @required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }
    Paint p = Paint();
    p.color = Colors.red;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 4;

    for (DetectedObject rectangle in objectList) {
      canvas.drawRect(rectangle.boundingBox, p);
      var list = rectangle.labels;
      for (Label label in list) {
        debugPrint("${label.text}   ${label.confidence.toStringAsFixed(2)}");
        TextSpan span = TextSpan(
            text: label.text,
            style: const TextStyle(fontSize: 25, color: Colors.blue));
        TextPainter tp = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas,
            Offset(rectangle.boundingBox.left, rectangle.boundingBox.top));
        break;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

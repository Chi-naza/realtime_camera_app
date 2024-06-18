import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realtime_camera_app/widgets/text_n_value_widget.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  File? _image;
  late ImagePicker imagePicker;

  String resultName = "";
  String resultConfidence = "0.0";

  @override
  void initState() {
    // init image picker
    imagePicker = ImagePicker();

    // call super
    super.initState();
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
                              image: DecorationImage(
                                  image: FileImage(_image!), fit: BoxFit.cover),
                            ),
                            // child: Image.file(_image!),
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
      // doImageLabeling(_image!);
    }
  }
}

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Camera App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;

  String result = "Result Will Be Shown Here";
  bool isBusy = false;
  CameraImage? image;

  @override
  void initState() {
    super.initState();
    // initialize controller with the back camera (i.e 0 index)
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    // initialize the camera of the device
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

      // Start streaming images from platform camera.
      controller.startImageStream((img) {
        if (!isBusy) {
          isBusy = true;
          image = img;
          doImageLabelling();
        }
      });

      // update state
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            debugPrint("Camera Access Denied: $e");
            break;
          default:
            debugPrint("Something Went Wrong with the Camera: $e");
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
                alignment: Alignment.bottomCenter,
                margin: const EdgeInsets.only(bottom: 40),
                child: Text(
                  result,
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          );
  }

  void doImageLabelling() {
    print("Streaming going now");
  }
}

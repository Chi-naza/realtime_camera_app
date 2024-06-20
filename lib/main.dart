import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:realtime_camera_app/object_detection/object_detection_screen.dart';
import 'package:realtime_camera_app/object_detection/object_detection_with_custom_model.dart';
import 'package:realtime_camera_app/realtime_image_detection/camera_screen.dart';
import 'package:realtime_camera_app/realtime_object_detection/obj_detection_camera_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CameraScreen(cameras: _cameras)));
              },
              child: const Text("Realtime Image Camera Screen"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ObjectDetectionScreen()));
              },
              child: const Text("Object Detection Screen"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            CustomModelObjectDetectionScreen()));
              },
              child: const Text("Custom Model Object Detection Screen"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ObjDetectionCameraScreen(cameras: _cameras),
                  ),
                );
              },
              child: const Text("R3ealtime Object Detection Screen"),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:smart_scanner/welcome_screen.dart';
import 'camera_screen.dart';

// Глобальная переменная для хранения списка доступных камер
List<CameraDescription> cameras = [];

Future<void> main() async {
  // Создать список доступных камер до инициализации приложения
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('CameraError: ${e.description}');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/camera': (context) => CameraScreen(cameras),
      },
      title: 'Smart Scanner',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        fontFamily: 'Blinker',
      ),
      home: WelcomeScreen(),
    );
  }
}

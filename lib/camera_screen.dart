import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'detail_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  CameraScreen(this.cameras);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController _controller;
  ScanMode _mode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    Future.delayed(Duration.zero, () {
      _mode = ModalRoute.of(context).settings.arguments as ScanMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.value.isInitialized
          ? Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CameraPreview(_controller),
                ),
                Positioned(
                    top: 50,
                    right: 10,
                    child: _controller.value.flashMode == FlashMode.off
                        ? IconButton(
                            icon: Icon(Icons.flash_off, color: Colors.white),
                            onPressed: () async {
                              await _controller.setFlashMode(FlashMode.torch);
                              setState(() {});
                            },
                          )
                        : IconButton(
                            icon: Icon(Icons.flash_on, color: Colors.white),
                            onPressed: () async {
                              await _controller.setFlashMode(FlashMode.off);
                              setState(() {});
                            },
                          )),
                Positioned(
                  bottom: 50,
                  right: 0,
                  left: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(width: 2, color: Colors.white)),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(30)),
                            child: Container(),
                            onPressed: () async {
                              // Если появился путь к файлу
                              // перейти на экран DetailScreen
                              await _takePicture().then((String path) {
                                if (path != null) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailScreen(
                                        imagePath: path,scanMode: _mode,
                                      ),
                                    ),
                                  );
                                } else {
                                  print('Путь к файлу не найден!');
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          : Container(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
    );
  }

  // Внутри _CameraScreenState класса

  void _initializeCamera() async {
    final CameraController cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    _controller = cameraController;

    _controller.initialize().then((_) async {
      if (!mounted) {
        return;
      }
      await _controller.setFlashMode(FlashMode.off);
      print(_controller.value.flashMode);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Делает снимок выбранной камерой
  // Возвращает путь к файлу
  Future<String> _takePicture() async {
    if (!_controller.value.isInitialized) {
      print("Контроллер не инициализирован");
      return null;
    }

    String imagePath;

    if (_controller.value.isTakingPicture) {
      print("Сохраняем фото...");
      return null;
    }

    try {
      // Сохранение в кроссплатформенном формате
      final XFile file = await _controller.takePicture();
      // Возвращение пути к файлу
      imagePath = file.path;
    } on CameraException catch (e) {
      print("Камера недоступна");
      return null;
    }

    return imagePath;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // App state changed before we got the chance to initialize.
    if (_controller == null || !_controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.paused) {
      _controller?.dispose()?.then((value) => _controller == null);
    } else if (state == AppLifecycleState.resumed) {
      setState(() {});
      _initializeCamera();
    }
  }
}

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'hairstyles_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: SplashScreen(camera: firstCamera),
    ),
  );
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  final CameraDescription camera;
  const SplashScreen({super.key, required this.camera});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait 3 seconds, then navigate to the main screen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => CutCamScreen(camera: widget.camera)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Displays your app logo (ensure assets/icon/app_icon.png exists)
            Image.asset(
              'assets/icon/app_icon.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image is missing, just to prevent crash
                return const Icon(Icons.camera_alt, size: 100, color: Colors.orange);
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'CutCam',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.orange),
          ],
        ),
      ),
    );
  }
}

// --- MAIN APP SCREEN ---

// Helper: Resize image BEFORE processing to prevent lag
img.Image convertCameraImage(CameraImage cameraImage) {
  final int width = cameraImage.width;
  final int height = cameraImage.height;
  final img.Image image = img.Image(width: width, height: height);
  
  final int uvRowStride = cameraImage.planes[1].bytesPerRow;
  final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;
  
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
      final int index = y * width + x;
      
      final yp = cameraImage.planes[0].bytes[index];
      final up = cameraImage.planes[1].bytes[uvIndex];
      final vp = cameraImage.planes[2].bytes[uvIndex];
      
      int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
      int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
      int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
      
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return image;
}

class CutCamScreen extends StatefulWidget {
  const CutCamScreen({super.key, required this.camera});
  final CameraDescription camera;

  @override
  State<CutCamScreen> createState() => _CutCamScreenState();
}

class _CutCamScreenState extends State<CutCamScreen> {
  late CameraController _controller;
  bool _isDetecting = false;
  Interpreter? _interpreter;
  List<Rect> _detectionBoxes = [];
  late int _inputSize;
  int _currentStepIndex = 0;
  
  final List<String> haircutSteps = const [
    'Step 1: #2 Guard - Cut the sides and back',
    'Step 2: #4 Guard - Cut the top',
    'Step 3: #3 Guard - Blend the top and sides',
    'Step 4: Clean up the back of the neck',
    'Step 5: Create a sharp line at the front',
  ];

  @override
  void initState() {
    super.initState();
    // Using LOW resolution to ensure the camera does not lag
    _controller = CameraController(widget.camera, ResolutionPreset.low, enableAudio: false);
    _controller.initialize().then((_) {
      if (!mounted) return;
      _loadModel(); 
    });
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/nanodet.tflite');
      final inputTensor = _interpreter!.getInputTensor(0);
      _inputSize = inputTensor.shape[1]; 

      _controller.startImageStream((image) {
        if (!_isDetecting) {
          _isDetecting = true;
          _runObjectDetection(image);
        }
      });
      setState(() {});
    } catch (e) {
      print("Failed to load model: $e");
    }
  }
  
  Uint8List imageToByteBuffer(img.Image image, int inputSize) {
    // Resize image to what the AI expects
    var resizedImage = img.copyResize(image, width: inputSize, height: inputSize);
    var buffer = Uint8List(1 * inputSize * inputSize * 3);
    var bufferIndex = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        var pixel = resizedImage.getPixel(x, y);
        buffer[bufferIndex++] = pixel.r.toInt();
        buffer[bufferIndex++] = pixel.g.toInt();
        buffer[bufferIndex++] = pixel.b.toInt();
      }
    }
    return buffer.buffer.asUint8List();
  }

  void _runObjectDetection(CameraImage image) async {
    if (_interpreter == null) return;
    
    await Future.delayed(const Duration(milliseconds: 100)); 

    try {
      var convertedImage = convertCameraImage(image);
      var preprocessedImage = imageToByteBuffer(convertedImage, _inputSize);

      var outputLocations = List.generate(1, (index) => List.generate(10, (index) => List.filled(4, 0.0)));
      var outputClasses = List.generate(1, (index) => List.filled(10, 0.0));
      var outputScores = List.generate(1, (index) => List.filled(10, 0.0));
      var numDetections = List.filled(1, 0.0);

      _interpreter!.runForMultipleInputs([preprocessedImage], {
        0: outputLocations, 1: outputClasses, 2: outputScores, 3: numDetections,
      });

      // --- SCALING LOGIC STARTS HERE ---
      // 1. Calculate how much we shrank the image
      // The AI sees a square (_inputSize x _inputSize), e.g., 300x300
      // The Camera image is rectangle (width x height)
      
      // Since we resized the camera image directly to inputSize x inputSize, 
      // the coordinates are relative to that square.
      // The SSD MobileNet model returns coordinates as [ymin, xmin, ymax, xmax] 
      // normalized between 0.0 and 1.0. This is the key! 
      // If they are normalized (0-1), we just multiply by the screen size in the Painter.
      
      final List<Rect> boxes = [];
      for (int i = 0; i < 10; i++) {
        if (outputScores[0][i] > 0.5) {
          // SSD MobileNet output is [ymin, xmin, ymax, xmax] 
          // AND it is normalized (0.0 to 1.0), so we don't need complex math here.
          // We just pass these 0.0-1.0 values to the painter, 
          // and the painter multiplies them by the actual canvas size.
          
          final rect = Rect.fromLTRB(
            outputLocations[0][i][1], // xmin
            outputLocations[0][i][0], // ymin
            outputLocations[0][i][3], // xmax
            outputLocations[0][i][2]  // ymax
          );
          
          boxes.add(rect);
        }
      }
      // --- SCALING LOGIC ENDS ---

      if (boxes.isNotEmpty) {
        print("AI: Found ${boxes.length} objects!"); 
      }

      if(mounted) {
        setState(() => _detectionBoxes = boxes);
      }
    } catch (e) {
      print("Detection Error: $e");
    } finally {
      _isDetecting = false;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CutCam'),
        actions: [
          IconButton(
            icon: const Icon(Icons.style),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HairstylesScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Camera Preview Area
          Expanded(
            flex: 3, 
            child: Stack(
              fit: StackFit.expand,
              children: [
                // AspectRatio ensures no stretching
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: CameraPreview(_controller),
                ),
                CustomPaint(painter: BoxPainter(_detectionBoxes)),
              ],
            ),
          ),
          
          // 2. Instructions Area
          Expanded(
            flex: 2, 
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.black, 
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Text(
                    haircutSteps[_currentStepIndex],
                    style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: haircutSteps.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _currentStepIndex == index
                              ? Colors.orange
                              : Colors.grey[800],
                          child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(haircutSteps[index]),
                        onTap: () => setState(() => _currentStepIndex = index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BoxPainter extends CustomPainter {
  final List<Rect> boxes;
  BoxPainter(this.boxes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (var box in boxes) {
      // Scale the 0.0-1.0 coordinates to the actual screen size
      final scaledRect = Rect.fromLTRB(
        box.left * size.width,   // xmin * screen_width
        box.top * size.height,   // ymin * screen_height
        box.right * size.width,  // xmax * screen_width
        box.bottom * size.height // ymax * screen_height
      );
      canvas.drawRect(scaledRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
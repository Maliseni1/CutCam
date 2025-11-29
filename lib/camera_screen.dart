import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';

// --- WRAPPER TO LOAD CAMERA ---
class CutCamScreenWrapper extends StatelessWidget {
  const CutCamScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CameraDescription>>(
      future: availableCameras(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return CutCamScreen(camera: snapshot.data!.first);
        }
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.orange)),
        );
      },
    );
  }
}

// --- MAIN CAMERA SCREEN ---
// --- ROTATION-AWARE IMAGE CONVERSION ---
img.Image convertCameraImage(CameraImage cameraImage) {
  final int width = cameraImage.width;
  final int height = cameraImage.height;
  
  // 1. Create the image buffer
  // Note: We create it with swapped width/height because we are going to rotate it
  // But for the initial byte copy, we use the original dimensions
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
  
  // 2. ROTATE THE IMAGE 90 DEGREES
  // Most portrait apps need a 90 degree rotation to be upright for the AI
  return img.copyRotate(image, angle: 90); 
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
  final FlutterTts flutterTts = FlutterTts();
  int _currentStepIndex = 0;
  bool _isHeadInFrame = false;
  
  final List<String> haircutSteps = const [
    'Step 1: #2 Guard - Sides & Back',
    'Step 2: #4 Guard - Top Section',
    'Step 3: #3 Guard - Blend Sides',
    'Step 4: Clean Neckline',
    'Step 5: Sharp Front Line',
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    // Use medium resolution for good balance of speed and clarity
    _controller = CameraController(widget.camera, ResolutionPreset.medium, enableAudio: false);
    _controller.initialize().then((_) {
      if (!mounted) return;
      _loadModel(); 
    });
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    _speak(haircutSteps[0]); 
  }

  Future<void> _speak(String text) async {
    await flutterTts.stop();
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
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

      final List<Rect> boxes = [];
      for (int i = 0; i < 10; i++) {
        double score = outputScores[0][i];
        double classId = outputClasses[0][i];

        if (score > 0.4 && classId == 0.0) {
          final box = Rect.fromLTRB(
            outputLocations[0][i][1], 
            outputLocations[0][i][0], 
            outputLocations[0][i][3], 
            outputLocations[0][i][2]
          );
          boxes.add(box);
        }
      }

      if(mounted) {
        setState(() {
          _detectionBoxes = boxes;
          _isHeadInFrame = boxes.isNotEmpty;
        });
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
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.orange)));
    }

    // --- STANDARD CALIBRATION LOGIC ---
    // 1. Get the aspect ratio of the camera sensor
    double aspectRatio = _controller.value.aspectRatio;
    
    // 2. If the phone is in portrait mode, we MUST flip the ratio
    //    (Because camera sensors are landscape by default)
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      aspectRatio = 1 / aspectRatio;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Calibrated Camera Viewfinder
          Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_controller),
                  CustomPaint(painter: BoxPainter(_detectionBoxes)),
                ],
              ),
            ),
          ),

          // 2. Back Button
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 3. Status Indicator
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: _isHeadInFrame ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isHeadInFrame ? "Target Locked" : "⚠ Position Head",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // 4. Instructions Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 220,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Text(
                      haircutSteps[_currentStepIndex],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: haircutSteps.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _currentStepIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _currentStepIndex = index);
                            _speak(haircutSteps[index]);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                            width: 60,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.orange : Colors.grey[800],
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSelected ? 20 : 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
    final boxPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final guideLinePaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var box in boxes) {
      final scaledRect = Rect.fromLTRB(
        box.left * size.width, 
        box.top * size.height, 
        box.right * size.width, 
        box.bottom * size.height
      );
      
      canvas.drawRect(scaledRect, boxPaint);

      final centerY = scaledRect.center.dy;
      canvas.drawLine(
        Offset(0, centerY), 
        Offset(size.width, centerY), 
        guideLinePaint
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
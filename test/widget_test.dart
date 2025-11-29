import 'package:camera/camera.dart';
import 'package:cutcam/camera_screen.dart'; // <--- NEW IMPORT
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CutCamScreen smoke test', (WidgetTester tester) async {
    // 1. Create a fake camera description so the screen doesn't crash
    final fakeCamera = const CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );

    // 2. Build the screen wrapped in a MaterialApp
    // We use CutCamScreen directly, which is now found in camera_screen.dart
    await tester.pumpWidget(MaterialApp(
      home: CutCamScreen(camera: fakeCamera),
    ));

    // 3. Verify that the screen actually loaded
    // It should show a loading indicator initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
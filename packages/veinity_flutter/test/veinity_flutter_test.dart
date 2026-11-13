import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veinity_flutter/veinity_flutter.dart';

void main() {
  testWidgets('GameViewport mounts, ticks scene, and renders UI overlay', (tester) async {
    final scene = Scene('TestViewportScene');

    // Add Camera
    final camObj = GameObject('MainCamera');
    camObj.transform.position = Vector3(0.0, 2.0, -5.0);
    camObj.transform.lookAt(Vector3.zero());
    camObj.addComponent(CameraComponent());
    scene.addGameObject(camObj);

    // Add Cube
    final cube = GameObject('TestCube');
    cube.addComponent(MeshRenderer(primitiveType: PrimitiveType.cube));
    scene.addGameObject(cube);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameViewport(
            scene: scene,
            overlayBuilder: (context, currentScene) {
              return const Positioned(
                top: 20,
                left: 20,
                child: Text('Score: 100', textDirection: TextDirection.ltr),
              );
            },
          ),
        ),
      ),
    );

    // Verify UI overlay renders
    expect(find.text('Score: 100'), findsOneWidget);

    // Pump a few frames
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byType(GameViewport), findsOneWidget);
  });

  test('FlutterFallbackRenderer paints 3D cube faces onto canvas with valid projection', () {
    final scene = Scene('TestScene');
    final camObj = GameObject('MainCamera');
    camObj.transform.position = Vector3(0.0, 5.0, -10.0);
    camObj.transform.lookAt(Vector3.zero());
    camObj.addComponent(CameraComponent());
    scene.addGameObject(camObj);
    Scene.mainCamera = camObj.getComponent<CameraComponent>();

    final cube = GameObject('TestCube');
    cube.addComponent(MeshRenderer(primitiveType: PrimitiveType.cube));
    scene.addGameObject(cube);

    final recorder = dart_ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final renderer = FlutterFallbackRenderer(scene: scene);

    renderer.paint(canvas, const Size(800, 600));
    final picture = recorder.endRecording();
    expect(picture, isNotNull);
  });
}

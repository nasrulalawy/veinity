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
}

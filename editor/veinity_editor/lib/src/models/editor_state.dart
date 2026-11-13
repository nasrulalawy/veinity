import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:veinity_flutter/veinity_flutter.dart';

/// Central state manager for the Veinity Desktop Game Engine Editor.
class EditorState extends ChangeNotifier {
  late Scene scene;
  GameObject? _selectedGameObject;
  bool _isPlaying = false;
  bool _isPaused = false;
  final List<String> _logs = [];

  EditorState() {
    initDefaultScene();
  }

  GameObject? get selectedGameObject => _selectedGameObject;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  List<String> get logs => List.unmodifiable(_logs);

  void initDefaultScene() {
    scene = Scene('SampleScene');

    // 1. Directional Sun
    final sun = GameObject('Directional Light');
    sun.transform.position = Vector3(5.0, 15.0, -5.0);
    sun.transform.lookAt(Vector3.zero());
    sun.addComponent(LightComponent(
      type: LightType.directional,
      intensity: 1.2,
      color: Vector3(1.0, 0.98, 0.9),
    ));
    scene.addGameObject(sun);

    // 2. Default Ground Plane
    final ground = GameObject('Ground');
    ground.transform.position = Vector3(0.0, -0.5, 0.0);
    ground.transform.localScale = Vector3(8.0, 0.2, 8.0);
    ground.addComponent(MeshRenderer(
      primitiveType: PrimitiveType.cube,
      material: MaterialData(baseColor: Vector4(0.3, 0.35, 0.4, 1.0)),
    ));
    scene.addGameObject(ground);

    // 3. Default Cube
    final cube = GameObject('Main Cube');
    cube.transform.position = Vector3(0.0, 1.0, 0.0);
    cube.addComponent(MeshRenderer(
      primitiveType: PrimitiveType.cube,
      material: MaterialData(baseColor: Vector4(0.2, 0.75, 0.85, 1.0)),
    ));
    cube.addComponent(Rigidbody3D(mass: 1.0, useGravity: true));
    scene.addGameObject(cube);

    // 4. Scene Camera
    final cam = GameObject('Main Camera');
    cam.transform.position = Vector3(0.0, 4.0, -8.0);
    cam.transform.lookAt(Vector3(0.0, 1.0, 0.0));
    cam.addComponent(CameraComponent(fieldOfView: 60.0));
    scene.addGameObject(cam);

    _selectedGameObject = cube;
    log('Scene "SampleScene" initialized with 4 GameObjects.');
  }

  void selectGameObject(GameObject? obj) {
    _selectedGameObject = obj;
    notifyListeners();
  }

  void log(String message) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _logs.add('[$timeStr] $message');
    if (_logs.length > 200) _logs.removeAt(0);
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    _isPaused = false;
    log(_isPlaying ? '▶ Entered Play Mode.' : '⏹ Exited Play Mode. Scene reset.');
    notifyListeners();
  }

  void togglePause() {
    if (!_isPlaying) return;
    _isPaused = !_isPaused;
    log(_isPaused ? '❚❚ Paused Play Mode.' : '▶ Resumed Play Mode.');
    notifyListeners();
  }

  void createGameObject(String name, {PrimitiveType? primitive}) {
    final obj = GameObject(name);
    obj.transform.position = Vector3(0.0, 1.5, 0.0);

    if (primitive != null) {
      final random = math.Random();
      final colors = [
        Vector4(0.9, 0.3, 0.3, 1.0),
        Vector4(0.3, 0.8, 0.4, 1.0),
        Vector4(0.3, 0.6, 0.9, 1.0),
        Vector4(0.9, 0.7, 0.2, 1.0),
        Vector4(0.8, 0.3, 0.8, 1.0),
      ];
      final color = colors[random.nextInt(colors.length)];

      obj.addComponent(MeshRenderer(
        primitiveType: primitive,
        material: MaterialData(baseColor: color),
      ));
      obj.addComponent(Rigidbody3D(mass: 1.0, useGravity: true));
    }

    scene.addGameObject(obj);
    _selectedGameObject = obj;
    log('Created GameObject "${obj.name}".');
    notifyListeners();
  }

  void deleteSelected() {
    if (_selectedGameObject == null) return;
    final name = _selectedGameObject!.name;
    _selectedGameObject!.destroy();
    _selectedGameObject = null;
    log('Deleted GameObject "$name".');
    notifyListeners();
  }

  void notifyObjectModified() {
    notifyListeners();
  }
}

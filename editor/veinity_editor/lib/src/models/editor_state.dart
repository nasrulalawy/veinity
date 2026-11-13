import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:veinity_flutter/veinity_flutter.dart';

/// Tools in the top-left Unity tool palette.
enum EditorTool {
  hand, // View Pan
  move, // Translate Gizmo
  rotate, // Rotate Gizmo
  scale, // Scale Gizmo
  transform, // Universal
}

/// Viewport tab mode (Scene View vs Game View).
enum ViewportTab {
  scene,
  game,
}

/// Pivot mode.
enum PivotMode {
  pivot,
  center,
}

/// Coordinate space.
enum HandleOrientation {
  global,
  local,
}

/// Log severity entry for Unity-style Console.
class ConsoleLogEntry {
  final String message;
  final String type; // 'info', 'warning', 'error'
  final DateTime timestamp;

  ConsoleLogEntry(this.message, {this.type = 'info'}) : timestamp = DateTime.now();

  String get timeString =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
}

/// Central state manager for the Veinity Desktop Game Engine Editor.
class EditorState extends ChangeNotifier {
  late Scene scene;
  GameObject? _selectedGameObject;

  EditorTool _activeTool = EditorTool.move;
  ViewportTab _activeViewportTab = ViewportTab.scene;
  PivotMode _pivotMode = PivotMode.pivot;
  HandleOrientation _handleOrientation = HandleOrientation.global;

  bool _isPlaying = false;
  bool _isPaused = false;
  final List<ConsoleLogEntry> _logs = [];

  EditorState() {
    initDefaultScene();
  }

  GameObject? get selectedGameObject => _selectedGameObject;
  EditorTool get activeTool => _activeTool;
  ViewportTab get activeViewportTab => _activeViewportTab;
  PivotMode get pivotMode => _pivotMode;
  HandleOrientation get handleOrientation => _handleOrientation;

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  List<ConsoleLogEntry> get logs => List.unmodifiable(_logs);

  void setTool(EditorTool tool) {
    _activeTool = tool;
    notifyListeners();
  }

  void setViewportTab(ViewportTab tab) {
    _activeViewportTab = tab;
    notifyListeners();
  }

  void togglePivotMode() {
    _pivotMode = _pivotMode == PivotMode.pivot ? PivotMode.center : PivotMode.pivot;
    notifyListeners();
  }

  void toggleHandleOrientation() {
    _handleOrientation =
        _handleOrientation == HandleOrientation.global ? HandleOrientation.local : HandleOrientation.global;
    notifyListeners();
  }

  void initDefaultScene() {
    scene = Scene('SampleScene');

    // 1. Directional Sun
    final sun = GameObject('Directional Light', 'Light');
    sun.transform.position = Vector3(5.0, 15.0, -5.0);
    sun.transform.lookAt(Vector3.zero());
    sun.addComponent(LightComponent(
      type: LightType.directional,
      intensity: 1.2,
      color: Vector3(1.0, 0.98, 0.9),
    ));
    scene.addGameObject(sun);

    // 2. Default Ground Plane
    final ground = GameObject('Plane', 'Ground');
    ground.transform.position = Vector3(0.0, 0.0, 0.0);
    ground.transform.localScale = Vector3(10.0, 1.0, 10.0);
    ground.addComponent(MeshRenderer(
      primitiveType: PrimitiveType.plane,
      material: MaterialData(baseColor: Vector4(0.35, 0.38, 0.42, 1.0)),
    ));
    scene.addGameObject(ground);

    // 3. Default Cube
    final cube = GameObject('Main Cube', 'Player');
    cube.transform.position = Vector3(0.0, 0.5, 0.0);
    cube.addComponent(MeshRenderer(
      primitiveType: PrimitiveType.cube,
      material: MaterialData(baseColor: Vector4(0.2, 0.75, 0.9, 1.0)),
    ));
    cube.addComponent(Rigidbody3D(mass: 1.0, useGravity: true));
    scene.addGameObject(cube);

    // 4. Scene Camera
    final cam = GameObject('Main Camera', 'MainCamera');
    cam.transform.position = Vector3(0.0, 3.5, -7.0);
    cam.transform.lookAt(Vector3(0.0, 0.5, 0.0));
    cam.addComponent(CameraComponent(fieldOfView: 60.0));
    scene.addGameObject(cam);

    _selectedGameObject = cube;
    log('Initialized scene "SampleScene" with 4 GameObjects.');
  }

  void selectGameObject(GameObject? obj) {
    _selectedGameObject = obj;
    notifyListeners();
  }

  void log(String message, {String type = 'info'}) {
    _logs.add(ConsoleLogEntry(message, type: type));
    if (_logs.length > 300) _logs.removeAt(0);
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    _isPaused = false;
    log(_isPlaying ? '▶ Entered Play Mode.' : '⏹ Exited Play Mode.');
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
    obj.transform.position = Vector3(0.0, 1.0, 0.0);

    if (primitive != null) {
      final random = math.Random();
      final colors = [
        Vector4(0.9, 0.35, 0.35, 1.0),
        Vector4(0.35, 0.8, 0.45, 1.0),
        Vector4(0.3, 0.65, 0.95, 1.0),
        Vector4(0.95, 0.75, 0.2, 1.0),
        Vector4(0.85, 0.35, 0.85, 1.0),
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

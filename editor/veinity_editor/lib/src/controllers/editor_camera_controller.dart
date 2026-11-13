import 'dart:math' as math;
import 'package:veinity_flutter/veinity_flutter.dart';

/// Handles interactive Orbit, Pan, and Zoom camera navigation in the Editor Scene Viewport.
class EditorCameraController {
  final GameObject cameraObject;

  double yaw = 0.0;
  double pitch = 25.0;
  double distance = 10.0;
  Vector3 focusTarget = Vector3(0.0, 1.0, 0.0);

  EditorCameraController({required this.cameraObject}) {
    updateCameraTransform();
  }

  void handleOrbit(double deltaX, double deltaY) {
    yaw += deltaX * 0.4;
    pitch = (pitch - deltaY * 0.4).clamp(-89.0, 89.0);
    updateCameraTransform();
  }

  void handlePan(double deltaX, double deltaY) {
    final right = cameraObject.transform.right;
    final up = cameraObject.transform.up;

    final panSpeed = distance * 0.0015;
    final movement = (right * -deltaX * panSpeed) + (up * deltaY * panSpeed);
    focusTarget += movement;
    updateCameraTransform();
  }

  void handleZoom(double delta) {
    final zoomSpeed = distance * 0.1;
    if (delta > 0) {
      distance = (distance + zoomSpeed).clamp(1.0, 200.0);
    } else {
      distance = (distance - zoomSpeed).clamp(1.0, 200.0);
    }
    updateCameraTransform();
  }

  void focusOn(Vector3 targetPosition) {
    focusTarget = targetPosition.clone();
    distance = 6.0;
    updateCameraTransform();
  }

  void updateCameraTransform() {
    final pitchRad = radians(pitch);
    final yawRad = radians(yaw);

    final x = focusTarget.x + distance * math.cos(pitchRad) * math.sin(yawRad);
    final y = focusTarget.y + distance * math.sin(pitchRad);
    final z = focusTarget.z - distance * math.cos(pitchRad) * math.cos(yawRad);

    cameraObject.transform.position = Vector3(x, y, z);
    cameraObject.transform.lookAt(focusTarget);
  }
}

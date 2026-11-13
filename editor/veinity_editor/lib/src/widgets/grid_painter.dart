import 'package:flutter/material.dart' hide Transform;
import 'package:veinity_flutter/veinity_flutter.dart';

/// Renders a 3D floor grid and selection gizmo on top of the Scene Viewport.
class GridPainter extends CustomPainter {
  final Scene scene;
  final GameObject? selectedObject;

  GridPainter({required this.scene, this.selectedObject});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final camera = Scene.mainCamera;
    if (camera == null) return;

    final aspectRatio = size.width / size.height;
    final viewProj = camera.calculateProjectionMatrix(aspectRatio) * camera.viewMatrix;

    // 1. Draw XZ Floor Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    final axisXPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    final axisZPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    const gridExtent = 10;
    const step = 1.0;

    for (var i = -gridExtent; i <= gridExtent; i++) {
      // Lines parallel to Z axis (varying X)
      final p1 = viewProj.transform(Vector4(i * step, 0.0, -gridExtent * step, 1.0));
      final p2 = viewProj.transform(Vector4(i * step, 0.0, gridExtent * step, 1.0));

      if (p1.w > 0.01 && p2.w > 0.01) {
        final s1 = _ndcToScreen(p1, size);
        final s2 = _ndcToScreen(p2, size);
        canvas.drawLine(s1, s2, i == 0 ? axisZPaint : gridPaint);
      }

      // Lines parallel to X axis (varying Z)
      final p3 = viewProj.transform(Vector4(-gridExtent * step, 0.0, i * step, 1.0));
      final p4 = viewProj.transform(Vector4(gridExtent * step, 0.0, i * step, 1.0));

      if (p3.w > 0.01 && p4.w > 0.01) {
        final s3 = _ndcToScreen(p3, size);
        final s4 = _ndcToScreen(p4, size);
        canvas.drawLine(s3, s4, i == 0 ? axisXPaint : gridPaint);
      }
    }

    // 2. Draw Selection Transform Gizmo (RGB = XYZ axes at selected object)
    if (selectedObject != null && !selectedObject!.isDestroyed) {
      final origin = selectedObject!.transform.position;
      final rot = selectedObject!.transform.rotation;

      final pOrigin = viewProj.transform(Vector4(origin.x, origin.y, origin.z, 1.0));
      if (pOrigin.w > 0.01) {
        final sOrigin = _ndcToScreen(pOrigin, size);

        // X Axis (Red)
        final xEnd = origin + rot.rotate(Vector3(1.2, 0.0, 0.0));
        final pX = viewProj.transform(Vector4(xEnd.x, xEnd.y, xEnd.z, 1.0));
        if (pX.w > 0.01) {
          canvas.drawLine(sOrigin, _ndcToScreen(pX, size), Paint()..color = Colors.red..strokeWidth = 2.5);
        }

        // Y Axis (Green)
        final yEnd = origin + rot.rotate(Vector3(0.0, 1.2, 0.0));
        final pY = viewProj.transform(Vector4(yEnd.x, yEnd.y, yEnd.z, 1.0));
        if (pY.w > 0.01) {
          canvas.drawLine(sOrigin, _ndcToScreen(pY, size), Paint()..color = Colors.greenAccent..strokeWidth = 2.5);
        }

        // Z Axis (Blue)
        final zEnd = origin + rot.rotate(Vector3(0.0, 0.0, 1.2));
        final pZ = viewProj.transform(Vector4(zEnd.x, zEnd.y, zEnd.z, 1.0));
        if (pZ.w > 0.01) {
          canvas.drawLine(sOrigin, _ndcToScreen(pZ, size), Paint()..color = Colors.lightBlueAccent..strokeWidth = 2.5);
        }

        // Center selection circle
        canvas.drawCircle(sOrigin, 4.0, Paint()..color = Colors.yellowAccent);
      }
    }
  }

  Offset _ndcToScreen(Vector4 clip, Size size) {
    final ndcX = clip.x / clip.w;
    final ndcY = clip.y / clip.w;
    final x = (ndcX + 1.0) * 0.5 * size.width;
    final y = (1.0 - ndcY) * 0.5 * size.height;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => true;
}

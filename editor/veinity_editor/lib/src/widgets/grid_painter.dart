import 'package:flutter/material.dart' hide Transform;
import 'package:veinity_flutter/veinity_flutter.dart';

/// Renders a 3D floor grid, selection bounding box, and transform gizmo in the Scene Viewport.
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
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;

    final axisXPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.75)
      ..strokeWidth = 2.0;

    final axisZPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.75)
      ..strokeWidth = 2.0;

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

    // 2. Draw Selection Wireframe Box & Transform Gizmo
    if (selectedObject != null && !selectedObject!.isDestroyed) {
      final worldMat = selectedObject!.transform.worldMatrix;
      final origin = selectedObject!.transform.position;
      final rot = selectedObject!.transform.rotation;

      // Draw Wireframe bounding cube outline around selected object
      final localCorners = [
        Vector3(-0.52, -0.52, -0.52), Vector3(0.52, -0.52, -0.52),
        Vector3(0.52, 0.52, -0.52),   Vector3(-0.52, 0.52, -0.52),
        Vector3(-0.52, -0.52, 0.52),  Vector3(0.52, -0.52, 0.52),
        Vector3(0.52, 0.52, 0.52),    Vector3(-0.52, 0.52, 0.52),
      ];

      final screenCorners = <Offset?>[];
      for (final corner in localCorners) {
        final wPos = worldMat.transform3(corner.clone());
        final clip = viewProj.transform(Vector4(wPos.x, wPos.y, wPos.z, 1.0));
        if (clip.w > 0.01) {
          screenCorners.add(_ndcToScreen(clip, size));
        } else {
          screenCorners.add(null);
        }
      }

      final outlinePaint = Paint()
        ..color = Colors.amberAccent
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // 12 Bounding Box Edges
      final edges = [
        [0, 1], [1, 2], [2, 3], [3, 0], // Back face
        [4, 5], [5, 6], [6, 7], [7, 4], // Front face
        [0, 4], [1, 5], [2, 6], [3, 7], // Connecting edges
      ];

      for (final edge in edges) {
        final c1 = screenCorners[edge[0]];
        final c2 = screenCorners[edge[1]];
        if (c1 != null && c2 != null) {
          canvas.drawLine(c1, c2, outlinePaint);
        }
      }

      // Draw RGB Transform Axis Gizmo at object pivot
      final pOrigin = viewProj.transform(Vector4(origin.x, origin.y, origin.z, 1.0));
      if (pOrigin.w > 0.01) {
        final sOrigin = _ndcToScreen(pOrigin, size);

        // X Axis (Red)
        final xEnd = origin + rot.asRotationMatrix().transform(Vector3(1.5, 0.0, 0.0));
        final pX = viewProj.transform(Vector4(xEnd.x, xEnd.y, xEnd.z, 1.0));
        if (pX.w > 0.01) {
          canvas.drawLine(sOrigin, _ndcToScreen(pX, size), Paint()..color = Colors.redAccent..strokeWidth = 3.0);
        }

        // Y Axis (Green)
        final yEnd = origin + rot.asRotationMatrix().transform(Vector3(0.0, 1.5, 0.0));
        final pY = viewProj.transform(Vector4(yEnd.x, yEnd.y, yEnd.z, 1.0));
        if (pY.w > 0.01) {
          canvas.drawLine(sOrigin, _ndcToScreen(pY, size), Paint()..color = Colors.greenAccent..strokeWidth = 3.0);
        }

        // Z Axis (Blue)
        final zEnd = origin + rot.asRotationMatrix().transform(Vector3(0.0, 0.0, 1.5));
        final pZ = viewProj.transform(Vector4(zEnd.x, zEnd.y, zEnd.z, 1.0));
        if (pZ.w > 0.01) {
          canvas.drawLine(sOrigin, _ndcToScreen(pZ, size), Paint()..color = Colors.lightBlueAccent..strokeWidth = 3.0);
        }

        // Center pivot point
        canvas.drawCircle(sOrigin, 5.0, Paint()..color = Colors.yellowAccent);
        canvas.drawCircle(sOrigin, 5.0, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.0);
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

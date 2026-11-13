import 'dart:math' as math;
import 'package:flutter/material.dart' hide Transform;
import 'package:veinity_flutter/veinity_flutter.dart';

/// Renders a 3D floor grid, scene gizmos (lights, cameras), selection bounding box,
/// and interactive RGB transform gizmos in the Unity-style Scene Viewport.
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
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    final axisXPaint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: 0.8)
      ..strokeWidth = 2.0;

    final axisZPaint = Paint()
      ..color = const Color(0xFF1E88E5).withValues(alpha: 0.8)
      ..strokeWidth = 2.0;

    const gridExtent = 12;
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

    // 2. Draw In-Scene Gizmos: Directional Lights
    _drawLightGizmos(canvas, size, viewProj);

    // 3. Draw In-Scene Gizmos: Cameras
    _drawCameraGizmos(canvas, size, viewProj);

    // 4. Draw Selection Wireframe Box & Transform Gizmo
    if (selectedObject != null && !selectedObject!.isDestroyed) {
      _drawSelectionBox(canvas, size, viewProj, selectedObject!);
      _drawTransformGizmo(canvas, size, viewProj, selectedObject!);
    }
  }

  void _drawLightGizmos(Canvas canvas, Size size, Matrix4 viewProj) {
    final lights = scene.findObjectsOfType<LightComponent>();
    for (final light in lights) {
      if (!light.gameObject.activeInHierarchy) continue;
      final pos = light.transform.position;
      final clip = viewProj.transform(Vector4(pos.x, pos.y, pos.z, 1.0));
      if (clip.w <= 0.01) continue;

      final sPos = _ndcToScreen(clip, size);

      // Outer glow & Sun disc
      canvas.drawCircle(
        sPos,
        14.0,
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        sPos,
        8.0,
        Paint()..color = const Color(0xFFFFC107),
      );
      canvas.drawCircle(
        sPos,
        8.0,
        Paint()
          ..color = const Color(0xFFFF8F00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Light direction rays
      final fwd = light.transform.forward.normalized();
      final rayPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.85)
        ..strokeWidth = 1.8;

      final offsets = [
        Vector3(0.0, 0.0, 0.0),
        Vector3(0.4, 0.2, 0.0),
        Vector3(-0.4, 0.2, 0.0),
        Vector3(0.0, -0.3, 0.3),
      ];

      for (final off in offsets) {
        final rStart = pos + off;
        final rEnd = rStart + fwd * 1.8;
        final cStart = viewProj.transform(Vector4(rStart.x, rStart.y, rStart.z, 1.0));
        final cEnd = viewProj.transform(Vector4(rEnd.x, rEnd.y, rEnd.z, 1.0));
        if (cStart.w > 0.01 && cEnd.w > 0.01) {
          canvas.drawLine(_ndcToScreen(cStart, size), _ndcToScreen(cEnd, size), rayPaint);
        }
      }
    }
  }

  void _drawCameraGizmos(Canvas canvas, Size size, Matrix4 viewProj) {
    final cameras = scene.findObjectsOfType<CameraComponent>();
    for (final cam in cameras) {
      if (cam.gameObject.name.contains('Scene View') || !cam.gameObject.activeInHierarchy) continue;
      final pos = cam.transform.position;
      final clip = viewProj.transform(Vector4(pos.x, pos.y, pos.z, 1.0));
      if (clip.w <= 0.01) continue;

      final sPos = _ndcToScreen(clip, size);

      // Camera body
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: sPos, width: 18, height: 12), const Radius.circular(2)),
        Paint()..color = const Color(0xFF64B5F6),
      );
      // Lens
      canvas.drawCircle(sPos, 3.5, Paint()..color = Colors.white);

      // Camera Frustum Pyramid outline
      final rot = cam.transform.rotation.asRotationMatrix();
      final frustumCorners = [
        pos + rot.transform(Vector3(-1.2, 0.8, 2.5)),
        pos + rot.transform(Vector3(1.2, 0.8, 2.5)),
        pos + rot.transform(Vector3(1.2, -0.8, 2.5)),
        pos + rot.transform(Vector3(-1.2, -0.8, 2.5)),
      ];

      final frustumPaint = Paint()
        ..color = const Color(0xFF90CAF9).withValues(alpha: 0.6)
        ..strokeWidth = 1.0;

      final sCorners = <Offset>[];
      for (final corner in frustumCorners) {
        final c = viewProj.transform(Vector4(corner.x, corner.y, corner.z, 1.0));
        if (c.w > 0.01) {
          final sc = _ndcToScreen(c, size);
          sCorners.add(sc);
          canvas.drawLine(sPos, sc, frustumPaint);
        }
      }

      if (sCorners.length == 4) {
        for (var i = 0; i < 4; i++) {
          canvas.drawLine(sCorners[i], sCorners[(i + 1) % 4], frustumPaint);
        }
      }
    }
  }

  void _drawSelectionBox(Canvas canvas, Size size, Matrix4 viewProj, GameObject obj) {
    final worldMat = obj.transform.worldMatrix;

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
      ..color = const Color(0xFFFFCA28)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

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
  }

  void _drawTransformGizmo(Canvas canvas, Size size, Matrix4 viewProj, GameObject obj) {
    final origin = obj.transform.position;
    final rot = obj.transform.rotation;
    final pOrigin = viewProj.transform(Vector4(origin.x, origin.y, origin.z, 1.0));
    if (pOrigin.w <= 0.01) return;

    final sOrigin = _ndcToScreen(pOrigin, size);
    final rotMat = rot.asRotationMatrix();

    // 1. Planar Handle Quads (XY, XZ, YZ)
    final pX1 = origin + rotMat.transform(Vector3(0.5, 0.0, 0.0));
    final pY1 = origin + rotMat.transform(Vector3(0.0, 0.5, 0.0));
    final pZ1 = origin + rotMat.transform(Vector3(0.0, 0.0, 0.5));
    final pXY = origin + rotMat.transform(Vector3(0.5, 0.5, 0.0));
    final pXZ = origin + rotMat.transform(Vector3(0.5, 0.0, 0.5));

    final cXY = viewProj.transform(Vector4(pXY.x, pXY.y, pXY.z, 1.0));
    final cXZ = viewProj.transform(Vector4(pXZ.x, pXZ.y, pXZ.z, 1.0));
    final cX1 = viewProj.transform(Vector4(pX1.x, pX1.y, pX1.z, 1.0));
    final cY1 = viewProj.transform(Vector4(pY1.x, pY1.y, pY1.z, 1.0));
    final cZ1 = viewProj.transform(Vector4(pZ1.x, pZ1.y, pZ1.z, 1.0));

    if (cXY.w > 0.01 && cX1.w > 0.01 && cY1.w > 0.01) {
      final xyPath = Path()
        ..moveTo(sOrigin.dx, sOrigin.dy)
        ..lineTo(_ndcToScreen(cX1, size).dx, _ndcToScreen(cX1, size).dy)
        ..lineTo(_ndcToScreen(cXY, size).dx, _ndcToScreen(cXY, size).dy)
        ..lineTo(_ndcToScreen(cY1, size).dx, _ndcToScreen(cY1, size).dy)
        ..close();
      canvas.drawPath(xyPath, Paint()..color = Colors.blue.withValues(alpha: 0.25));
    }

    if (cXZ.w > 0.01 && cX1.w > 0.01 && cZ1.w > 0.01) {
      final xzPath = Path()
        ..moveTo(sOrigin.dx, sOrigin.dy)
        ..lineTo(_ndcToScreen(cX1, size).dx, _ndcToScreen(cX1, size).dy)
        ..lineTo(_ndcToScreen(cXZ, size).dx, _ndcToScreen(cXZ, size).dy)
        ..lineTo(_ndcToScreen(cZ1, size).dx, _ndcToScreen(cZ1, size).dy)
        ..close();
      canvas.drawPath(xzPath, Paint()..color = Colors.green.withValues(alpha: 0.25));
    }

    // 2. X Axis (Red)
    final xEnd = origin + rotMat.transform(Vector3(1.6, 0.0, 0.0));
    final pX = viewProj.transform(Vector4(xEnd.x, xEnd.y, xEnd.z, 1.0));
    if (pX.w > 0.01) {
      final sX = _ndcToScreen(pX, size);
      canvas.drawLine(sOrigin, sX, Paint()..color = const Color(0xFFEF5350)..strokeWidth = 3.0);
      _drawArrowHead(canvas, sOrigin, sX, const Color(0xFFEF5350));
    }

    // 3. Y Axis (Green)
    final yEnd = origin + rotMat.transform(Vector3(0.0, 1.6, 0.0));
    final pY = viewProj.transform(Vector4(yEnd.x, yEnd.y, yEnd.z, 1.0));
    if (pY.w > 0.01) {
      final sY = _ndcToScreen(pY, size);
      canvas.drawLine(sOrigin, sY, Paint()..color = const Color(0xFF66BB6A)..strokeWidth = 3.0);
      _drawArrowHead(canvas, sOrigin, sY, const Color(0xFF66BB6A));
    }

    // 4. Z Axis (Blue)
    final zEnd = origin + rotMat.transform(Vector3(0.0, 0.0, 1.6));
    final pZ = viewProj.transform(Vector4(zEnd.x, zEnd.y, zEnd.z, 1.0));
    if (pZ.w > 0.01) {
      final sZ = _ndcToScreen(pZ, size);
      canvas.drawLine(sOrigin, sZ, Paint()..color = const Color(0xFF42A5F5)..strokeWidth = 3.0);
      _drawArrowHead(canvas, sOrigin, sZ, const Color(0xFF42A5F5));
    }

    // 5. Center Pivot Point (Yellow Dot)
    canvas.drawCircle(sOrigin, 5.0, Paint()..color = const Color(0xFFFFEE58));
    canvas.drawCircle(
      sOrigin,
      5.0,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Color color) {
    final dir = to - from;
    final length = dir.distance;
    if (length < 2.0) return;

    final unit = dir / length;
    final normal = Offset(-unit.dy, unit.dx);
    const arrowLen = 10.0;
    const arrowWidth = 5.0;

    final tip = to;
    final left = to - unit * arrowLen + normal * arrowWidth;
    final right = to - unit * arrowLen - normal * arrowWidth;

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
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

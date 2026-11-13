import 'dart:math' as math;
import 'package:flutter/material.dart' hide Transform;
import 'package:veinity_core/veinity_core.dart';

class _RenderFace {
  final List<Offset> screenPoints;
  final double depth;
  final Color color;

  _RenderFace({
    required this.screenPoints,
    required this.depth,
    required this.color,
  });
}

/// A pure Flutter 3D Software/Raster CustomPainter that renders scene meshes,
/// lighting, and camera projections directly onto the Flutter canvas.
class FlutterFallbackRenderer extends CustomPainter {
  final Scene scene;

  FlutterFallbackRenderer({required this.scene});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Clear background
    final camera = Scene.mainCamera;
    final clearColor = camera != null
        ? Color.from(
            alpha: camera.clearColor.w.clamp(0.0, 1.0),
            red: camera.clearColor.x.clamp(0.0, 1.0),
            green: camera.clearColor.y.clamp(0.0, 1.0),
            blue: camera.clearColor.z.clamp(0.0, 1.0),
          )
        : const Color(0xFF1E1E28);

    canvas.drawColor(clearColor, BlendMode.src);

    if (camera == null) return;

    final aspectRatio = size.width / size.height;
    final viewProj = camera.calculateProjectionMatrix(aspectRatio) * camera.viewMatrix;

    // 2. Find light
    final lights = scene.findObjectsOfType<LightComponent>();
    final mainLight = lights.isNotEmpty ? lights.first : null;
    final lightDir = (mainLight != null
            ? mainLight.transform.forward
            : Vector3(0.5, 1.0, 0.3))
        .normalized();

    // 3. Collect and project faces
    final meshes = scene.findObjectsOfType<MeshRenderer>();
    final facesToRender = <_RenderFace>[];

    for (final mesh in meshes) {
      if (!mesh.enabled || !mesh.gameObject.activeInHierarchy) continue;
      _collectMeshFaces(mesh, viewProj, lightDir, size, facesToRender);
    }

    // 4. Painter's Algorithm: Sort faces from furthest to nearest
    facesToRender.sort((a, b) => b.depth.compareTo(a.depth));

    // 5. Draw faces
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.black26;

    for (final face in facesToRender) {
      if (face.screenPoints.length < 3) continue;

      final path = Path()..moveTo(face.screenPoints[0].dx, face.screenPoints[0].dy);
      for (var i = 1; i < face.screenPoints.length; i++) {
        path.lineTo(face.screenPoints[i].dx, face.screenPoints[i].dy);
      }
      path.close();

      fillPaint.color = face.color;
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  void _collectMeshFaces(
    MeshRenderer mesh,
    Matrix4 viewProj,
    Vector3 lightDir,
    Size size,
    List<_RenderFace> outFaces,
  ) {
    final worldMat = mesh.transform.worldMatrix;
    final baseColor = mesh.material.baseColor;
    final rawColor = Color.from(
      alpha: baseColor.w.clamp(0.0, 1.0),
      red: baseColor.x.clamp(0.0, 1.0),
      green: baseColor.y.clamp(0.0, 1.0),
      blue: baseColor.z.clamp(0.0, 1.0),
    );

    // Standard Unit Cube Vertices [-0.5, 0.5]
    final cubeQuads = [
      // Front (Z+)
      [Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5)],
      // Back (Z-)
      [Vector3(0.5, -0.5, -0.5), Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, 0.5, -0.5), Vector3(0.5, 0.5, -0.5)],
      // Top (Y+)
      [Vector3(-0.5, 0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(0.5, 0.5, -0.5), Vector3(-0.5, 0.5, -0.5)],
      // Bottom (Y-)
      [Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5), Vector3(0.5, -0.5, 0.5), Vector3(-0.5, -0.5, 0.5)],
      // Right (X+)
      [Vector3(0.5, -0.5, 0.5), Vector3(0.5, -0.5, -0.5), Vector3(0.5, 0.5, -0.5), Vector3(0.5, 0.5, 0.5)],
      // Left (X-)
      [Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, 0.5, 0.5), Vector3(-0.5, 0.5, -0.5)],
    ];

    final List<List<Vector3>> quads;
    if (mesh.primitiveType == PrimitiveType.plane) {
      quads = [
        [Vector3(-0.5, 0.0, 0.5), Vector3(0.5, 0.0, 0.5), Vector3(0.5, 0.0, -0.5), Vector3(-0.5, 0.0, -0.5)],
      ];
    } else {
      quads = cubeQuads;
    }

    for (final quad in quads) {
      final worldVertices = quad.map((v) => worldMat.transform3(v.clone())).toList();

      // Calculate face normal
      final edge1 = worldVertices[1] - worldVertices[0];
      final edge2 = worldVertices[2] - worldVertices[0];
      final normal = edge1.cross(edge2).normalized();

      // Calculate directional lighting intensity (Lambertian + Ambient)
      final nDotL = math.max(0.0, normal.dot(lightDir));
      final lightFactor = (0.35 + 0.65 * nDotL).clamp(0.0, 1.0);

      final litColor = Color.from(
        alpha: rawColor.a,
        red: (rawColor.r * lightFactor).clamp(0.0, 1.0),
        green: (rawColor.g * lightFactor).clamp(0.0, 1.0),
        blue: (rawColor.b * lightFactor).clamp(0.0, 1.0),
      );

      // Project vertices to screen
      final screenPoints = <Offset>[];
      var totalDepth = 0.0;
      var isBehindCamera = false;

      for (final wV in worldVertices) {
        final clip = viewProj.transform(Vector4(wV.x, wV.y, wV.z, 1.0));
        if (clip.w <= 0.01) {
          isBehindCamera = true;
          break;
        }

        final ndcX = clip.x / clip.w;
        final ndcY = clip.y / clip.w;
        final screenX = (ndcX + 1.0) * 0.5 * size.width;
        final screenY = (1.0 - ndcY) * 0.5 * size.height;

        screenPoints.add(Offset(screenX, screenY));
        totalDepth += clip.w;
      }

      if (!isBehindCamera && screenPoints.length == 4) {
        outFaces.add(_RenderFace(
          screenPoints: screenPoints,
          depth: totalDepth / 4.0,
          color: litColor,
        ));
      }
    }
  }

  @override
  bool shouldRepaint(covariant FlutterFallbackRenderer oldDelegate) => true;
}

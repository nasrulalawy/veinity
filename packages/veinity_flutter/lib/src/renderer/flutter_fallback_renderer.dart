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

    // 1. Procedural Unity-style Atmospheric Skybox & Ground Gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF233040), // Unity Deep Sky
          Color(0xFF384A5F), // Mid-sky
          Color(0xFF4C5E74), // Luminous Horizon Haze
          Color(0xFF292C34), // Just below horizon
          Color(0xFF1B1D22), // Ground Nadir
        ],
        stops: [0.0, 0.44, 0.50, 0.56, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    final camera = Scene.mainCamera;
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
    } else if (mesh.primitiveType == PrimitiveType.sphere) {
      quads = _generateSphereFaces();
    } else if (mesh.primitiveType == PrimitiveType.cylinder) {
      quads = _generateCylinderFaces();
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

      if (!isBehindCamera && screenPoints.length >= 3) {
        outFaces.add(_RenderFace(
          screenPoints: screenPoints,
          depth: totalDepth / screenPoints.length,
          color: litColor,
        ));
      }
    }
  }

  static List<List<Vector3>> _generateSphereFaces() {
    final faces = <List<Vector3>>[];
    const latBands = 6;
    const lonBands = 8;
    const radius = 0.5;

    for (var lat = 0; lat < latBands; lat++) {
      final theta1 = lat * math.pi / latBands;
      final theta2 = (lat + 1) * math.pi / latBands;

      for (var lon = 0; lon < lonBands; lon++) {
        final phi1 = lon * 2.0 * math.pi / lonBands;
        final phi2 = (lon + 1) * 2.0 * math.pi / lonBands;

        final v1 = Vector3(
          radius * math.sin(theta1) * math.cos(phi1),
          radius * math.cos(theta1),
          radius * math.sin(theta1) * math.sin(phi1),
        );
        final v2 = Vector3(
          radius * math.sin(theta1) * math.cos(phi2),
          radius * math.cos(theta1),
          radius * math.sin(theta1) * math.sin(phi2),
        );
        final v3 = Vector3(
          radius * math.sin(theta2) * math.cos(phi2),
          radius * math.cos(theta2),
          radius * math.sin(theta2) * math.sin(phi2),
        );
        final v4 = Vector3(
          radius * math.sin(theta2) * math.cos(phi1),
          radius * math.cos(theta2),
          radius * math.sin(theta2) * math.sin(phi1),
        );

        if (lat == 0) {
          faces.add([v1, v3, v4]);
        } else if (lat == latBands - 1) {
          faces.add([v1, v2, v3]);
        } else {
          faces.add([v1, v2, v3, v4]);
        }
      }
    }
    return faces;
  }

  static List<List<Vector3>> _generateCylinderFaces() {
    final faces = <List<Vector3>>[];
    const segments = 8;
    const radius = 0.5;
    const halfHeight = 0.5;

    for (var i = 0; i < segments; i++) {
      final a1 = i * 2.0 * math.pi / segments;
      final a2 = (i + 1) * 2.0 * math.pi / segments;

      final x1 = radius * math.cos(a1);
      final z1 = radius * math.sin(a1);
      final x2 = radius * math.cos(a2);
      final z2 = radius * math.sin(a2);

      // Side wall quad
      faces.add([
        Vector3(x1, -halfHeight, z1),
        Vector3(x2, -halfHeight, z2),
        Vector3(x2, halfHeight, z2),
        Vector3(x1, halfHeight, z1),
      ]);

      // Top cap triangle
      faces.add([
        Vector3(0.0, halfHeight, 0.0),
        Vector3(x2, halfHeight, z2),
        Vector3(x1, halfHeight, z1),
      ]);

      // Bottom cap triangle
      faces.add([
        Vector3(0.0, -halfHeight, 0.0),
        Vector3(x1, -halfHeight, z1),
        Vector3(x2, -halfHeight, z2),
      ]);
    }
    return faces;
  }

  @override
  bool shouldRepaint(covariant FlutterFallbackRenderer oldDelegate) => true;
}

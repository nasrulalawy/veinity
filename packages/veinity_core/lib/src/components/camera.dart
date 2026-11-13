import 'package:vector_math/vector_math_64.dart';
import '../annotations/inspectable.dart';
import '../ecs/component.dart';
import '../ecs/scene.dart';

/// Camera projection mode.
enum CameraProjection {
  perspective,
  orthographic,
}

/// Represents a 3D camera that views and renders the scene.
class CameraComponent extends Component {
  @Inspectable(label: 'Projection Mode')
  CameraProjection projection = CameraProjection.perspective;

  @Inspectable(label: 'Field of View', min: 10.0, max: 120.0, step: 1.0)
  double fieldOfView = 60.0;

  @Inspectable(label: 'Near Clip Plane', min: 0.01, max: 10.0)
  double nearClipPlane = 0.1;

  @Inspectable(label: 'Far Clip Plane', min: 10.0, max: 10000.0)
  double farClipPlane = 1000.0;

  @Inspectable(label: 'Orthographic Size', min: 0.1, max: 100.0)
  double orthographicSize = 5.0;

  /// Clear color (RGBA in 0.0 .. 1.0 range).
  Vector4 clearColor = Vector4(0.1, 0.1, 0.15, 1.0);

  CameraComponent({
    this.projection = CameraProjection.perspective,
    this.fieldOfView = 60.0,
    this.nearClipPlane = 0.1,
    this.farClipPlane = 1000.0,
    this.orthographicSize = 5.0,
    Vector4? clearColor,
  }) {
    if (clearColor != null) this.clearColor = clearColor;
  }

  @override
  void onAwake() {
    super.onAwake();
    Scene.mainCamera ??= this;
  }

  @override
  void onDestroy() {
    if (Scene.mainCamera == this) {
      Scene.mainCamera = null;
    }
    super.onDestroy();
  }

  /// Calculates the view matrix matching standard OpenGL/Metal projection conventions.
  Matrix4 get viewMatrix {
    final pos = transform.position;
    final f = transform.forward;
    final u = transform.up;
    return makeViewMatrix(pos, pos + f, u);
  }

  /// Calculates the projection matrix for the given viewport aspect ratio.
  Matrix4 calculateProjectionMatrix(double aspectRatio) {
    if (projection == CameraProjection.perspective) {
      return makePerspectiveMatrix(
        radians(fieldOfView),
        aspectRatio,
        nearClipPlane,
        farClipPlane,
      );
    } else {
      final halfHeight = orthographicSize;
      final halfWidth = halfHeight * aspectRatio;
      return makeOrthographicMatrix(
        -halfWidth,
        halfWidth,
        -halfHeight,
        halfHeight,
        nearClipPlane,
        farClipPlane,
      );
    }
  }

  /// Casts a ray from camera position through a 2D screen coordinate.
  Ray screenPointToRay(Vector2 screenPoint, Vector2 screenSize) {
    final ndcX = (screenPoint.x / screenSize.x) * 2.0 - 1.0;
    final ndcY = 1.0 - (screenPoint.y / screenSize.y) * 2.0;

    final proj = calculateProjectionMatrix(screenSize.x / screenSize.y);
    final invViewProj = Matrix4.copy(proj * viewMatrix)..invert();

    final nearPoint = invViewProj.transform3(Vector3(ndcX, ndcY, -1.0));
    final farPoint = invViewProj.transform3(Vector3(ndcX, ndcY, 1.0));
    final direction = (farPoint - nearPoint).normalized();

    return Ray.originDirection(transform.position, direction);
  }
}

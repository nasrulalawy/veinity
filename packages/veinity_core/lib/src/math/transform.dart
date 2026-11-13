import '../ecs/game_object.dart';
import 'math_types.dart';

/// Coordinate space for transformations.
enum Space {
  self,
  world,
}

/// Defines the position, rotation, and scale of a [GameObject] in 3D space,
/// and manages parent-child transform hierarchies.
class Transform {
  final GameObject gameObject;

  Vector3 _localPosition = Vector3.zero();
  Quaternion _localRotation = Quaternion.identity();
  Vector3 _localScale = Vector3.all(1.0);

  Transform? _parent;
  final List<Transform> _children = [];

  // Matrix caching with dirty flags
  bool _isWorldDirty = true;
  final Matrix4 _worldMatrix = Matrix4.identity();
  Vector3 _worldPosition = Vector3.zero();
  Quaternion _worldRotation = Quaternion.identity();

  Transform(this.gameObject);

  // --- Local Properties ---

  Vector3 get localPosition => _localPosition;
  set localPosition(Vector3 value) {
    _localPosition = value;
    _setDirty();
  }

  Quaternion get localRotation => _localRotation;
  set localRotation(Quaternion value) {
    _localRotation = value;
    _setDirty();
  }

  Vector3 get localScale => _localScale;
  set localScale(Vector3 value) {
    _localScale = value;
    _setDirty();
  }

  /// Euler angles in degrees (X: Pitch, Y: Yaw, Z: Roll).
  Vector3 get localEulerAngles {
    // Basic conversion or direct extraction
    return Vector3(
      degrees(_localRotation.x),
      degrees(_localRotation.y),
      degrees(_localRotation.z),
    );
  }

  set localEulerAngles(Vector3 eulerDegrees) {
    localRotation = QuaternionHelpers.fromEuler(
      eulerDegrees.x,
      eulerDegrees.y,
      eulerDegrees.z,
    );
  }

  // --- Hierarchy ---

  Transform? get parent => _parent;

  set parent(Transform? newParent) {
    if (_parent == newParent) return;

    if (_parent != null) {
      _parent!._children.remove(this);
    }

    _parent = newParent;

    if (newParent != null) {
      newParent._children.add(this);
    }

    _setDirty();
  }

  List<Transform> get children => List.unmodifiable(_children);
  int get childCount => _children.length;

  Transform getChild(int index) => _children[index];

  // --- World Properties ---

  Matrix4 get worldMatrix {
    _updateWorldDataIfNeeded();
    return _worldMatrix;
  }

  Vector3 get position {
    _updateWorldDataIfNeeded();
    return _worldPosition;
  }

  set position(Vector3 newWorldPos) {
    if (_parent == null) {
      localPosition = newWorldPos;
    } else {
      // Invert parent world matrix to find local coordinates
      final invParent = Matrix4.copy(_parent!.worldMatrix)..invert();
      final local = invParent.transform3(newWorldPos.clone());
      localPosition = local;
    }
  }

  Quaternion get rotation {
    _updateWorldDataIfNeeded();
    return _worldRotation;
  }

  set rotation(Quaternion newWorldRot) {
    if (_parent == null) {
      localRotation = newWorldRot;
    } else {
      final invParentRot = Quaternion.copy(_parent!.rotation)..inverse();
      localRotation = invParentRot * newWorldRot;
    }
  }

  // Direction vectors (normalized) in world space
  Vector3 get forward {
    final rot = rotation;
    return rot.rotate(Vector3Helpers.forward);
  }

  Vector3 get back => -forward;

  Vector3 get up {
    final rot = rotation;
    return rot.rotate(Vector3Helpers.up);
  }

  Vector3 get down => -up;

  Vector3 get right {
    final rot = rotation;
    return rot.rotate(Vector3Helpers.right);
  }

  Vector3 get left => -right;

  // --- Transformations ---

  /// Translates the transform by [translation].
  void translate(Vector3 translation, [Space space = Space.self]) {
    if (space == Space.world) {
      position = position + translation;
    } else {
      final oriented = rotation.rotate(translation);
      position = position + oriented;
    }
  }

  /// Rotates the transform around Euler angles in degrees.
  void rotate(Vector3 eulerDegrees, [Space space = Space.self]) {
    final deltaRot = QuaternionHelpers.fromEuler(
      eulerDegrees.x,
      eulerDegrees.y,
      eulerDegrees.z,
    );
    if (space == Space.world) {
      rotation = deltaRot * rotation;
    } else {
      localRotation = localRotation * deltaRot;
    }
  }

  /// Rotates the transform to look at [targetPosition] in world space.
  void lookAt(Vector3 targetPosition, [Vector3? worldUp]) {
    final direction = targetPosition - position;
    if (direction.length2 < 0.000001) return;
    rotation = QuaternionHelpers.lookRotation(direction, worldUp ?? Vector3Helpers.up);
  }

  // --- Internal Matrix Cache Invalidation ---

  void _setDirty() {
    if (!_isWorldDirty) {
      _isWorldDirty = true;
      for (var i = 0; i < _children.length; i++) {
        _children[i]._setDirty();
      }
    }
  }

  void _updateWorldDataIfNeeded() {
    if (!_isWorldDirty) return;

    final localMat = Matrix4.compose(
      _localPosition,
      _localRotation,
      _localScale,
    );

    if (_parent == null) {
      _worldMatrix.setFrom(localMat);
      _worldPosition = _localPosition.clone();
      _worldRotation = Quaternion.copy(_localRotation);
    } else {
      _worldMatrix.setFrom(_parent!.worldMatrix * localMat);
      _worldPosition = _worldMatrix.getTranslation();
      _worldRotation = _parent!.rotation * _localRotation;
    }

    _isWorldDirty = false;
  }
}

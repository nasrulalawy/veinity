import 'package:vector_math/vector_math_64.dart';
import 'game_object.dart';

/// Details about a 3D physical collision between two GameObjects.
class Collision3D {
  /// The GameObject involved in the collision.
  final GameObject gameObject;

  /// The point in world coordinates where the contact occurred.
  final Vector3 contactPoint;

  /// The surface normal vector at the contact point.
  final Vector3 normal;

  /// The relative linear velocity of the two colliding objects.
  final Vector3 relativeVelocity;

  Collision3D({
    required this.gameObject,
    required this.contactPoint,
    required this.normal,
    required this.relativeVelocity,
  });
}

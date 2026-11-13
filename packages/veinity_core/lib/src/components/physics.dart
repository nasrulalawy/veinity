import 'package:vector_math/vector_math_64.dart';
import '../annotations/inspectable.dart';
import '../ecs/component.dart';

/// How a force is applied to a Rigidbody.
enum ForceMode {
  /// Continuous force, dependent on mass (F = m * a).
  force,

  /// Instantaneous impulse, dependent on mass.
  impulse,

  /// Continuous acceleration, ignoring mass.
  acceleration,

  /// Instantaneous velocity change, ignoring mass.
  velocityChange,
}

/// Abstract base class for all 3D colliders.
abstract class Collider3D extends Component {
  @Inspectable(label: 'Center Offset')
  Vector3 center = Vector3.zero();

  @Inspectable(label: 'Is Trigger')
  bool isTrigger = false;
}

/// A box-shaped 3D collision volume.
class BoxCollider3D extends Collider3D {
  @Inspectable(label: 'Size')
  Vector3 size = Vector3.all(1.0);

  BoxCollider3D({Vector3? center, Vector3? size, bool isTrigger = false}) {
    if (center != null) this.center = center;
    if (size != null) this.size = size;
    this.isTrigger = isTrigger;
  }
}

/// A spherical 3D collision volume.
class SphereCollider3D extends Collider3D {
  @Inspectable(label: 'Radius', min: 0.01, max: 100.0)
  double radius = 0.5;

  SphereCollider3D({Vector3? center, this.radius = 0.5, bool isTrigger = false}) {
    if (center != null) this.center = center;
    this.isTrigger = isTrigger;
  }
}

/// Controls physical simulation (gravity, mass, velocity, forces) on a GameObject.
class Rigidbody3D extends Component {
  @Inspectable(label: 'Mass (kg)', min: 0.001, max: 100000.0)
  double mass = 1.0;

  @Inspectable(label: 'Linear Drag', min: 0.0, max: 100.0)
  double drag = 0.0;

  @Inspectable(label: 'Angular Drag', min: 0.0, max: 100.0)
  double angularDrag = 0.05;

  @Inspectable(label: 'Use Gravity')
  bool useGravity = true;

  @Inspectable(label: 'Is Kinematic')
  bool isKinematic = false;

  /// Current linear velocity of the rigidbody in m/s.
  Vector3 velocity = Vector3.zero();

  /// Current angular velocity in radians/sec.
  Vector3 angularVelocity = Vector3.zero();

  /// Whether the rigidbody is currently resting on the ground/surface.
  bool isGrounded = false;

  // Accumulated forces for the next physics tick
  Vector3 _accumulatedForce = Vector3.zero();
  Vector3 _accumulatedTorque = Vector3.zero();

  Rigidbody3D({
    this.mass = 1.0,
    this.drag = 0.0,
    this.angularDrag = 0.05,
    this.useGravity = true,
    this.isKinematic = false,
  });

  /// Applies a continuous force to the rigidbody.
  void addForce(Vector3 force, [ForceMode mode = ForceMode.force]) {
    if (isKinematic) return;
    switch (mode) {
      case ForceMode.force:
        _accumulatedForce += force / (mass > 0 ? mass : 1.0);
        break;
      case ForceMode.acceleration:
        _accumulatedForce += force;
        break;
      case ForceMode.impulse:
        velocity += force / (mass > 0 ? mass : 1.0);
        break;
      case ForceMode.velocityChange:
        velocity += force;
        break;
    }
  }

  /// Applies an instantaneous impulse to the rigidbody.
  void applyImpulse(Vector3 impulse) {
    addForce(impulse, ForceMode.impulse);
  }

  /// Applies rotational torque to the rigidbody.
  void addTorque(Vector3 torque) {
    if (isKinematic) return;
    _accumulatedTorque += torque / (mass > 0 ? mass : 1.0);
  }

  @override
  void onFixedUpdate(double fixedDt) {
    if (isKinematic) return;

    // Apply basic default gravity if not handled by native physics engine
    if (useGravity) {
      velocity += Vector3(0.0, -9.81, 0.0) * fixedDt;
    }

    // Apply accumulated forces
    velocity += _accumulatedForce * fixedDt;
    _accumulatedForce = Vector3.zero();

    // Linear drag
    if (drag > 0) {
      velocity *= (1.0 - (drag * fixedDt).clamp(0.0, 1.0));
    }

    // Integrate position
    transform.position = transform.position + (velocity * fixedDt);

    // Integrate torque & rotation
    angularVelocity += _accumulatedTorque * fixedDt;
    _accumulatedTorque = Vector3.zero();

    if (angularDrag > 0) {
      angularVelocity *= (1.0 - (angularDrag * fixedDt).clamp(0.0, 1.0));
    }

    if (angularVelocity.length2 > 0.000001) {
      final angle = angularVelocity.length * fixedDt;
      final axis = angularVelocity.normalized();
      final deltaRot = Quaternion.axisAngle(axis, angle);
      transform.rotation = deltaRot * transform.rotation;
    }
  }
}


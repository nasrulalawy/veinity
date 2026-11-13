import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' hide Colors;
export 'package:vector_math/vector_math_64.dart' hide Colors;

/// Extension providing Unity-like constants and helpers for [Vector3].
extension Vector3Helpers on Vector3 {
  static Vector3 get zero => Vector3.zero();
  static Vector3 get one => Vector3.all(1.0);
  static Vector3 get up => Vector3(0.0, 1.0, 0.0);
  static Vector3 get down => Vector3(0.0, -1.0, 0.0);
  static Vector3 get right => Vector3(1.0, 0.0, 0.0);
  static Vector3 get left => Vector3(-1.0, 0.0, 0.0);
  static Vector3 get forward => Vector3(0.0, 0.0, 1.0);
  static Vector3 get back => Vector3(0.0, 0.0, -1.0);

  /// Returns a copy of this vector.
  Vector3 clone() => Vector3.copy(this);

  /// Moves this vector towards a target by maxDistanceDelta.
  static Vector3 moveTowards(Vector3 current, Vector3 target, double maxDistanceDelta) {
    final toVector = target - current;
    final dist = toVector.length;
    if (dist <= maxDistanceDelta || dist == 0.0) {
      return target.clone();
    }
    return current + (toVector / dist) * maxDistanceDelta;
  }

  /// Linearly interpolates between two vectors.
  static Vector3 lerp(Vector3 a, Vector3 b, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    return a + (b - a) * clampedT;
  }
}

/// Extension providing Unity-like helpers for [Quaternion].
extension QuaternionHelpers on Quaternion {
  static Quaternion get identity => Quaternion.identity();

  /// Creates a rotation from Euler angles in degrees (Yaw, Pitch, Roll).
  static Quaternion fromEuler(double pitchDegrees, double yawDegrees, double rollDegrees) {
    return Quaternion.euler(
      radians(yawDegrees),
      radians(pitchDegrees),
      radians(rollDegrees),
    );
  }

  /// Creates a rotation looking in [direction] with the specified [up] vector.
  static Quaternion lookRotation(Vector3 forward, [Vector3? up]) {
    final f = forward.normalized();
    final u = (up ?? Vector3Helpers.up).normalized();

    var right = u.cross(f);
    if (right.length2 < 0.0001) {
      right = Vector3Helpers.right.cross(f);
    }
    right.normalize();
    final actualUp = f.cross(right).normalized();

    final m = Matrix3.columns(right, actualUp, f);
    return Quaternion.fromRotation(m);
  }

  /// Spherical linear interpolation (SLERP) between two quaternions.
  static Quaternion slerp(Quaternion a, Quaternion b, double t) {
    final clampedT = t.clamp(0.0, 1.0);

    var cosHalfTheta = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
    var bx = b.x;
    var by = b.y;
    var bz = b.z;
    var bw = b.w;

    // Take the shortest path
    if (cosHalfTheta < 0.0) {
      cosHalfTheta = -cosHalfTheta;
      bx = -bx;
      by = -by;
      bz = -bz;
      bw = -bw;
    }

    if (cosHalfTheta >= 0.9995) {
      // Linear interpolation to prevent division by zero
      final result = Quaternion(
        a.x + clampedT * (bx - a.x),
        a.y + clampedT * (by - a.y),
        a.z + clampedT * (bz - a.z),
        a.w + clampedT * (bw - a.w),
      );
      result.normalize();
      return result;
    }

    final halfTheta = math.acos(cosHalfTheta);
    final sinHalfTheta = math.sin(halfTheta);

    final ratioA = math.sin((1.0 - clampedT) * halfTheta) / sinHalfTheta;
    final ratioB = math.sin(clampedT * halfTheta) / sinHalfTheta;

    return Quaternion(
      a.x * ratioA + bx * ratioB,
      a.y * ratioA + by * ratioB,
      a.z * ratioA + bz * ratioB,
      a.w * ratioA + bw * ratioB,
    );
  }
}

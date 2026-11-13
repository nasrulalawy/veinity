import 'package:vector_math/vector_math_64.dart';
import '../annotations/inspectable.dart';
import '../ecs/component.dart';

/// Type of 3D light source.
enum LightType {
  directional,
  point,
  spot,
}

/// Emits light in 3D space to illuminate meshes and cast shadows.
class LightComponent extends Component {
  @Inspectable(label: 'Light Type')
  LightType type = LightType.directional;

  @Inspectable(label: 'Color')
  Vector3 color = Vector3(1.0, 1.0, 1.0);

  @Inspectable(label: 'Intensity', min: 0.0, max: 100000.0)
  double intensity = 1.0;

  @Inspectable(label: 'Range (Point/Spot)', min: 0.1, max: 500.0)
  double range = 10.0;

  @Inspectable(label: 'Spot Angle (Degrees)', min: 1.0, max: 179.0)
  double spotAngle = 45.0;

  @Inspectable(label: 'Cast Shadows')
  bool castShadows = true;

  LightComponent({
    this.type = LightType.directional,
    Vector3? color,
    this.intensity = 1.0,
    this.range = 10.0,
    this.spotAngle = 45.0,
    this.castShadows = true,
  }) {
    if (color != null) this.color = color;
  }
}


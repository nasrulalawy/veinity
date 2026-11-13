import 'package:vector_math/vector_math_64.dart';
import '../annotations/inspectable.dart';
import '../ecs/component.dart';

/// Primitive 3D geometric shapes that can be generated procedurally.
enum PrimitiveType {
  cube,
  sphere,
  plane,
  cylinder,
  custom,
}

/// Standard Physically Based Rendering (PBR) material data.
class MaterialData {
  @Inspectable(label: 'Base Color')
  Vector4 baseColor = Vector4(1.0, 1.0, 1.0, 1.0);

  @Inspectable(label: 'Metallic', min: 0.0, max: 1.0)
  double metallic = 0.0;

  @Inspectable(label: 'Roughness', min: 0.0, max: 1.0)
  double roughness = 0.5;

  @Inspectable(label: 'Emissive Color')
  Vector3 emissiveColor = Vector3.zero();

  @Inspectable(label: 'Albedo Texture Path')
  String? albedoTexture;

  @Inspectable(label: 'Normal Map Path')
  String? normalMap;

  MaterialData({
    Vector4? baseColor,
    this.metallic = 0.0,
    this.roughness = 0.5,
    Vector3? emissiveColor,
    this.albedoTexture,
    this.normalMap,
  }) {
    if (baseColor != null) this.baseColor = baseColor;
    if (emissiveColor != null) this.emissiveColor = emissiveColor;
  }
}

/// Renders a 3D mesh (GLTF / primitive) with a PBR material at the GameObject's transform.
class MeshRenderer extends Component {
  @Inspectable(label: 'Primitive Type')
  PrimitiveType primitiveType = PrimitiveType.cube;

  @Inspectable(label: 'Asset Path (glTF/glb)')
  String? modelAssetPath;

  @Inspectable(label: 'Cast Shadows')
  bool castShadows = true;

  @Inspectable(label: 'Receive Shadows')
  bool receiveShadows = true;

  /// Material used to shade this mesh.
  MaterialData material = MaterialData();

  MeshRenderer({
    this.primitiveType = PrimitiveType.cube,
    this.modelAssetPath,
    this.castShadows = true,
    this.receiveShadows = true,
    MaterialData? material,
  }) {
    if (material != null) this.material = material;
  }
}


import 'package:flutter/material.dart' hide Transform;
import 'package:veinity_flutter/veinity_flutter.dart';
import '../models/editor_state.dart';
import '../theme/unity_theme.dart';

/// Unity-style Inspector Panel for viewing and editing GameObject & Component properties.
class InspectorPanel extends StatefulWidget {
  final EditorState state;

  const InspectorPanel({super.key, required this.state});

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  @override
  Widget build(BuildContext context) {
    final obj = widget.state.selectedGameObject;

    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: UnityTheme.panelBg,
        border: Border(left: BorderSide(color: UnityTheme.border, width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tab Header: [ Inspector ]
          Container(
            height: 26,
            color: UnityTheme.panelHeaderInactive,
            child: Row(
              children: [
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: const BoxDecoration(
                    color: UnityTheme.panelBg,
                    border: Border(
                      top: BorderSide(color: UnityTheme.borderLight, width: 1.0),
                      right: BorderSide(color: UnityTheme.border, width: 1.0),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Inspector', style: UnityTheme.headerStyle),
                ),
                const Spacer(),
                const Icon(Icons.lock_outline, size: 13, color: UnityTheme.textMuted),
                const SizedBox(width: 8),
                const Icon(Icons.more_vert, size: 14, color: UnityTheme.textMuted),
                const SizedBox(width: 6),
              ],
            ),
          ),

          if (obj == null)
            const Expanded(
              child: Center(
                child: Text('No GameObject selected', style: UnityTheme.labelStyle),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  // 2. Unity GameObject Header (Active + Name + Static + Tag/Layer)
                  _buildUnityObjectHeader(obj),
                  const SizedBox(height: 10),

                  // 3. Transform Component (Always present)
                  _buildUnityTransformCard(obj),
                  const SizedBox(height: 8),

                  // 4. Attached Components
                  for (final comp in obj.components) ...[
                    _buildComponentSection(obj, comp),
                    const SizedBox(height: 8),
                  ],

                  // 5. Material & Shader Inspector (if MeshRenderer attached)
                  if (obj.tryGetComponent<MeshRenderer>() != null) ...[
                    _buildMaterialCard(obj.tryGetComponent<MeshRenderer>()!),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 12),

                  // 6. Centered Unity "Add Component" Button
                  _buildAddComponentButton(obj),
                  const SizedBox(height: 24),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnityObjectHeader(GameObject obj) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Row + Active checkbox + Static checkbox
        Row(
          children: [
            Checkbox(
              value: obj.activeSelf,
              activeColor: UnityTheme.selectionBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (val) {
                if (val != null) {
                  setState(() => obj.setActive(val));
                  widget.state.notifyObjectModified();
                }
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  color: UnityTheme.inputBg,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: UnityTheme.inputBorder),
                ),
                child: TextFormField(
                  initialValue: obj.name,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: UnityTheme.textBright),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  ),
                  onChanged: (val) {
                    obj.name = val;
                    widget.state.notifyObjectModified();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Static', style: UnityTheme.labelStyle),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 14, color: UnityTheme.textMuted),
          ],
        ),

        const SizedBox(height: 6),

        // Tag & Layer Row
        Row(
          children: [
            const SizedBox(width: 6),
            const Text('Tag', style: TextStyle(fontSize: 10.5, color: UnityTheme.textMuted)),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHeaderDropdown(obj.tag, ['Untagged', 'Player', 'Enemy', 'Ground', 'MainCamera']),
            ),
            const SizedBox(width: 12),
            const Text('Layer', style: TextStyle(fontSize: 10.5, color: UnityTheme.textMuted)),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHeaderDropdown('Default', ['Default', 'TransparentFX', 'Ignore Raycast', 'Water', 'UI']),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderDropdown(String value, List<String> items) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: UnityTheme.buttonBg,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: UnityTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: UnityTheme.textMain),
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 12, color: UnityTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildUnityTransformCard(GameObject obj) {
    return _ComponentContainer(
      title: 'Transform',
      icon: Icons.open_with,
      child: Column(
        children: [
          _buildVector3Field('Position', obj.transform.localPosition, (v) {
            obj.transform.localPosition = v;
            widget.state.notifyObjectModified();
          }),
          const SizedBox(height: 4),
          _buildVector3Field('Rotation', obj.transform.localEulerAngles, (v) {
            obj.transform.localEulerAngles = v;
            widget.state.notifyObjectModified();
          }),
          const SizedBox(height: 4),
          _buildVector3Field('Scale', obj.transform.localScale, (v) {
            obj.transform.localScale = v;
            widget.state.notifyObjectModified();
          }),
        ],
      ),
    );
  }

  Widget _buildVector3Field(String label, Vector3 vec, ValueChanged<Vector3> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(label, style: const TextStyle(fontSize: 11, color: UnityTheme.textMain)),
        ),
        Expanded(child: _buildAxisInput('X', vec.x, UnityTheme.axisX, (x) => onChanged(Vector3(x, vec.y, vec.z)))),
        const SizedBox(width: 4),
        Expanded(child: _buildAxisInput('Y', vec.y, UnityTheme.axisY, (y) => onChanged(Vector3(vec.x, y, vec.z)))),
        const SizedBox(width: 4),
        Expanded(child: _buildAxisInput('Z', vec.z, UnityTheme.axisZ, (z) => onChanged(Vector3(vec.x, vec.y, z)))),
      ],
    );
  }

  Widget _buildAxisInput(String axis, double val, Color axisColor, ValueChanged<double> onChanged) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: UnityTheme.inputBg,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: UnityTheme.inputBorder),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              axis,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: axisColor),
            ),
          ),
          Expanded(
            child: TextFormField(
              key: ValueKey('${axis}_$val'),
              initialValue: val.toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: const TextStyle(fontSize: 10.5, color: UnityTheme.textMain, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 12),
              ),
              onFieldSubmitted: (text) {
                final parsed = double.tryParse(text);
                if (parsed != null) onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentSection(GameObject obj, Component comp) {
    if (comp is MeshRenderer) return _buildMeshRendererSection(comp);
    if (comp is Rigidbody3D) return _buildRigidbodySection(comp);
    if (comp is BoxCollider3D) return _buildBoxColliderSection(comp);
    if (comp is SphereCollider3D) return _buildSphereColliderSection(comp);
    if (comp is LightComponent) return _buildLightSection(comp);
    if (comp is CameraComponent) return _buildCameraSection(comp);

    return _ComponentContainer(
      title: comp.runtimeType.toString(),
      icon: Icons.code,
      child: Text('Custom Component (${comp.runtimeType})', style: UnityTheme.labelStyle),
    );
  }

  Widget _buildBoxColliderSection(BoxCollider3D box) {
    return _ComponentContainer(
      title: 'Box Collider',
      icon: Icons.check_box_outline_blank,
      child: Column(
        children: [
          _buildPropRow('Is Trigger', Checkbox(
            value: box.isTrigger,
            activeColor: UnityTheme.selectionBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (v) {
              if (v != null) {
                setState(() => box.isTrigger = v);
                widget.state.notifyObjectModified();
              }
            },
          )),
          const SizedBox(height: 4),
          _buildVector3Row('Center', box.center, (c) {
            box.center = c;
            widget.state.notifyObjectModified();
          }),
          const SizedBox(height: 4),
          _buildVector3Row('Size', box.size, (s) {
            box.size = s;
            widget.state.notifyObjectModified();
          }),
        ],
      ),
    );
  }

  Widget _buildSphereColliderSection(SphereCollider3D sphere) {
    return _ComponentContainer(
      title: 'Sphere Collider',
      icon: Icons.circle_outlined,
      child: Column(
        children: [
          _buildPropRow('Is Trigger', Checkbox(
            value: sphere.isTrigger,
            activeColor: UnityTheme.selectionBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (v) {
              if (v != null) {
                setState(() => sphere.isTrigger = v);
                widget.state.notifyObjectModified();
              }
            },
          )),
          const SizedBox(height: 4),
          _buildVector3Row('Center', sphere.center, (c) {
            sphere.center = c;
            widget.state.notifyObjectModified();
          }),
          const SizedBox(height: 4),
          _buildPropRow('Radius', SizedBox(
            width: 80,
            height: 20,
            child: Container(
              decoration: BoxDecoration(color: UnityTheme.inputBg, border: Border.all(color: UnityTheme.inputBorder)),
              child: TextFormField(
                initialValue: sphere.radius.toStringAsFixed(2),
                style: const TextStyle(fontSize: 10.5, color: UnityTheme.textMain),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(left: 4, bottom: 12)),
                onFieldSubmitted: (v) {
                  final parsed = double.tryParse(v);
                  if (parsed != null) {
                    sphere.radius = parsed;
                    widget.state.notifyObjectModified();
                  }
                },
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(MeshRenderer mesh) {
    final mat = mesh.material;
    final baseColor = mat.baseColor;
    final displayColor = Color.from(
      alpha: baseColor.w.clamp(0.0, 1.0),
      red: baseColor.x.clamp(0.0, 1.0),
      green: baseColor.y.clamp(0.0, 1.0),
      blue: baseColor.z.clamp(0.0, 1.0),
    );

    return _ComponentContainer(
      title: 'Material (Standard PBR)',
      icon: Icons.blur_circular,
      child: Column(
        children: [
          _buildPropRow('Shader', const Text('Standard', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: UnityTheme.textBright))),
          const SizedBox(height: 6),
          _buildPropRow('Rendering Mode', const Text('Opaque', style: TextStyle(fontSize: 11, color: UnityTheme.textMain))),
          const SizedBox(height: 6),
          // Albedo Color Row
          _buildPropRow('Albedo', Row(
            children: [
              Container(
                width: 32,
                height: 18,
                decoration: BoxDecoration(
                  color: displayColor,
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'RGBA: ${(baseColor.x * 255).toInt()}, ${(baseColor.y * 255).toInt()}, ${(baseColor.z * 255).toInt()}',
                style: const TextStyle(fontSize: 10, color: UnityTheme.textMuted),
              ),
            ],
          )),
          const SizedBox(height: 6),
          // Metallic Slider
          _buildPropRow('Metallic', SliderTheme(
            data: SliderThemeData(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
            child: Slider(
              value: mat.metallic.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              activeColor: UnityTheme.selectionBlue,
              onChanged: (v) {
                setState(() => mat.metallic = v);
                widget.state.notifyObjectModified();
              },
            ),
          )),
          // Smoothness Slider
          _buildPropRow('Smoothness', SliderTheme(
            data: SliderThemeData(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
            child: Slider(
              value: (1.0 - mat.roughness).clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              activeColor: UnityTheme.selectionBlue,
              onChanged: (v) {
                setState(() => mat.roughness = (1.0 - v).clamp(0.0, 1.0));
                widget.state.notifyObjectModified();
              },
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMeshRendererSection(MeshRenderer mesh) {
    return _ComponentContainer(
      title: 'Mesh Renderer',
      icon: Icons.view_in_ar,
      child: Column(
        children: [
          _buildPropRow('Primitive', DropdownButton<PrimitiveType>(
            value: mesh.primitiveType,
            isDense: true,
            dropdownColor: UnityTheme.panelBg,
            underline: const SizedBox(),
            items: PrimitiveType.values.map((p) {
              return DropdownMenuItem(value: p, child: Text(p.name, style: const TextStyle(fontSize: 11, color: UnityTheme.textMain)));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => mesh.primitiveType = val);
                widget.state.notifyObjectModified();
              }
            },
          )),
          const SizedBox(height: 6),
          _buildPropRow('Cast Shadows', Checkbox(
            value: mesh.castShadows,
            activeColor: UnityTheme.selectionBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (v) {
              if (v != null) {
                setState(() => mesh.castShadows = v);
                widget.state.notifyObjectModified();
              }
            },
          )),
        ],
      ),
    );
  }

  Widget _buildRigidbodySection(Rigidbody3D rb) {
    return _ComponentContainer(
      title: 'Rigidbody',
      icon: Icons.fitness_center,
      child: Column(
        children: [
          _buildPropRow('Mass', SizedBox(
            width: 80,
            height: 20,
            child: Container(
              decoration: BoxDecoration(color: UnityTheme.inputBg, border: Border.all(color: UnityTheme.inputBorder)),
              child: TextFormField(
                initialValue: rb.mass.toString(),
                style: const TextStyle(fontSize: 10.5, color: UnityTheme.textMain),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(left: 4, bottom: 12)),
                onFieldSubmitted: (v) {
                  final val = double.tryParse(v);
                  if (val != null) {
                    rb.mass = val;
                    widget.state.notifyObjectModified();
                  }
                },
              ),
            ),
          )),
          const SizedBox(height: 4),
          _buildPropRow('Use Gravity', Checkbox(
            value: rb.useGravity,
            activeColor: UnityTheme.selectionBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (v) {
              if (v != null) {
                setState(() => rb.useGravity = v);
                widget.state.notifyObjectModified();
              }
            },
          )),
          const SizedBox(height: 4),
          _buildPropRow('Is Kinematic', Checkbox(
            value: rb.isKinematic,
            activeColor: UnityTheme.selectionBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (v) {
              if (v != null) {
                setState(() => rb.isKinematic = v);
                widget.state.notifyObjectModified();
              }
            },
          )),
        ],
      ),
    );
  }

  Widget _buildLightSection(LightComponent light) {
    return _ComponentContainer(
      title: 'Light',
      icon: Icons.lightbulb_outline,
      child: Column(
        children: [
          _buildPropRow('Type', Text(light.type.name.toUpperCase(), style: const TextStyle(fontSize: 11, color: UnityTheme.textMain))),
          const SizedBox(height: 4),
          _buildPropRow('Intensity', SliderTheme(
            data: SliderThemeData(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
            child: Slider(
              value: light.intensity.clamp(0.0, 10.0),
              min: 0.0,
              max: 10.0,
              activeColor: UnityTheme.selectionBlue,
              onChanged: (v) {
                setState(() => light.intensity = v);
                widget.state.notifyObjectModified();
              },
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCameraSection(CameraComponent cam) {
    return _ComponentContainer(
      title: 'Camera',
      icon: Icons.videocam_outlined,
      child: Column(
        children: [
          _buildPropRow('Field of View', SliderTheme(
            data: SliderThemeData(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
            child: Slider(
              value: cam.fieldOfView,
              min: 20.0,
              max: 110.0,
              activeColor: UnityTheme.selectionBlue,
              onChanged: (v) {
                setState(() => cam.fieldOfView = v);
                widget.state.notifyObjectModified();
              },
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPropRow(String label, Widget control) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11, color: UnityTheme.textMuted))),
        Expanded(child: Align(alignment: Alignment.centerLeft, child: control)),
      ],
    );
  }

  Widget _buildAddComponentButton(GameObject obj) {
    return Center(
      child: PopupMenuButton<String>(
        onSelected: (type) {
          if (type == 'rb') obj.addComponent(Rigidbody3D());
          if (type == 'box') obj.addComponent(BoxCollider3D());
          if (type == 'sphere') obj.addComponent(SphereCollider3D());
          if (type == 'mesh') obj.addComponent(MeshRenderer());
          if (type == 'light') obj.addComponent(LightComponent(type: LightType.point));
          if (type == 'camera') obj.addComponent(CameraComponent());
          setState(() {});
          widget.state.notifyObjectModified();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(height: 22, value: 'rb', child: Text('Physics > Rigidbody', style: TextStyle(fontSize: 11))),
          PopupMenuItem(height: 22, value: 'box', child: Text('Physics > Box Collider', style: TextStyle(fontSize: 11))),
          PopupMenuItem(height: 22, value: 'sphere', child: Text('Physics > Sphere Collider', style: TextStyle(fontSize: 11))),
          PopupMenuDivider(height: 1),
          PopupMenuItem(height: 22, value: 'mesh', child: Text('Mesh > Mesh Renderer', style: TextStyle(fontSize: 11))),
          PopupMenuItem(height: 22, value: 'light', child: Text('Rendering > Light', style: TextStyle(fontSize: 11))),
          PopupMenuItem(height: 22, value: 'camera', child: Text('Rendering > Camera', style: TextStyle(fontSize: 11))),
        ],
        child: Container(
          width: 220,
          height: 26,
          decoration: BoxDecoration(
            color: UnityTheme.buttonBg,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: UnityTheme.border),
          ),
          alignment: Alignment.center,
          child: const Text('Add Component', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: UnityTheme.textBright)),
        ),
      ),
    );
  }
}

class _ComponentContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ComponentContainer({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UnityTheme.panelBg,
        border: Border.all(color: UnityTheme.borderLight, width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: UnityTheme.panelHeader,
            child: Row(
              children: [
                const Icon(Icons.arrow_drop_down, size: 14, color: UnityTheme.textMuted),
                Icon(icon, size: 13, color: UnityTheme.textMain),
                const SizedBox(width: 4),
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: UnityTheme.textBright)),
                const Spacer(),
                const Icon(Icons.more_vert, size: 13, color: UnityTheme.textMuted),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: child,
          ),
        ],
      ),
    );
  }
}

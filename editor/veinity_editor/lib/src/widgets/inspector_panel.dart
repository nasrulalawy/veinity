import 'package:flutter/material.dart' hide Transform;
import 'package:veinity_flutter/veinity_flutter.dart';
import '../models/editor_state.dart';

/// Right-side Inspector panel for editing selected GameObject and Component properties.
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
      decoration: BoxDecoration(
        color: const Color(0xFF1E2227),
        border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF282C34),
            child: const Row(
              children: [
                Icon(Icons.tune, size: 16, color: Colors.cyanAccent),
                SizedBox(width: 8),
                Text(
                  'INSPECTOR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          if (obj == null)
            const Expanded(
              child: Center(
                child: Text(
                  'No GameObject selected\nSelect an object in the Hierarchy',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // GameObject Header (Active + Name + Tag)
                  _buildObjectHeader(obj),
                  const Divider(color: Colors.white12, height: 24),

                  // Transform Component (Always present)
                  _buildTransformCard(obj),
                  const SizedBox(height: 12),

                  // Attached Components
                  for (final comp in obj.components) ...[
                    _buildComponentCard(obj, comp),
                    const SizedBox(height: 12),
                  ],

                  // Add Component Button
                  _buildAddComponentButton(obj),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildObjectHeader(GameObject obj) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: obj.activeSelf,
              onChanged: (val) {
                if (val != null) {
                  setState(() => obj.setActive(val));
                  widget.state.notifyObjectModified();
                }
              },
            ),
            Expanded(
              child: TextFormField(
                initialValue: obj.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                onChanged: (val) {
                  obj.name = val;
                  widget.state.notifyObjectModified();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Tag:', style: TextStyle(fontSize: 12, color: Colors.white60)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(obj.tag, style: const TextStyle(fontSize: 11, color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransformCard(GameObject obj) {
    return _CardWrapper(
      title: 'Transform',
      icon: Icons.open_with,
      child: Column(
        children: [
          _buildVector3Row('Position', obj.transform.localPosition, (v) {
            obj.transform.localPosition = v;
            widget.state.notifyObjectModified();
          }),
          const SizedBox(height: 6),
          _buildVector3Row('Rotation', obj.transform.localEulerAngles, (v) {
            obj.transform.localEulerAngles = v;
            widget.state.notifyObjectModified();
          }),
          const SizedBox(height: 6),
          _buildVector3Row('Scale', obj.transform.localScale, (v) {
            obj.transform.localScale = v;
            widget.state.notifyObjectModified();
          }),
        ],
      ),
    );
  }

  Widget _buildVector3Row(String label, Vector3 vec, ValueChanged<Vector3> onChanged) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70))),
        Expanded(child: _buildNumberInput('X', vec.x, Colors.redAccent, (x) => onChanged(Vector3(x, vec.y, vec.z)))),
        const SizedBox(width: 4),
        Expanded(child: _buildNumberInput('Y', vec.y, Colors.greenAccent, (y) => onChanged(Vector3(vec.x, y, vec.z)))),
        const SizedBox(width: 4),
        Expanded(child: _buildNumberInput('Z', vec.z, Colors.blueAccent, (z) => onChanged(Vector3(vec.x, vec.y, z)))),
      ],
    );
  }

  Widget _buildNumberInput(String axis, double value, Color axisColor, ValueChanged<double> onChanged) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: axisColor.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
            ),
            child: Text(axis, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: axisColor)),
          ),
          Expanded(
            child: TextFormField(
              key: ValueKey('${axis}_$value'),
              initialValue: value.toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: const TextStyle(fontSize: 11, color: Colors.white),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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

  Widget _buildComponentCard(GameObject obj, Component comp) {
    if (comp is MeshRenderer) return _buildMeshRendererCard(comp);
    if (comp is Rigidbody3D) return _buildRigidbodyCard(comp);
    if (comp is LightComponent) return _buildLightCard(comp);
    if (comp is CameraComponent) return _buildCameraCard(comp);

    return _CardWrapper(
      title: comp.runtimeType.toString(),
      icon: Icons.extension_outlined,
      onDelete: () {
        setState(() => obj.removeComponent(comp));
        widget.state.notifyObjectModified();
      },
      child: Text('Custom Component (${comp.runtimeType})', style: const TextStyle(fontSize: 11, color: Colors.white60)),
    );
  }

  Widget _buildMeshRendererCard(MeshRenderer mesh) {
    return _CardWrapper(
      title: 'Mesh Renderer',
      icon: Icons.view_in_ar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Primitive:', style: TextStyle(fontSize: 11, color: Colors.white70)),
              const Spacer(),
              DropdownButton<PrimitiveType>(
                value: mesh.primitiveType,
                isDense: true,
                dropdownColor: const Color(0xFF282C34),
                items: PrimitiveType.values.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p.name, style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => mesh.primitiveType = val);
                    widget.state.notifyObjectModified();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Cast Shadows:', style: TextStyle(fontSize: 11, color: Colors.white70)),
              const Spacer(),
              Switch(
                value: mesh.castShadows,
                onChanged: (v) {
                  setState(() => mesh.castShadows = v);
                  widget.state.notifyObjectModified();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRigidbodyCard(Rigidbody3D rb) {
    return _CardWrapper(
      title: 'Rigidbody 3D',
      icon: Icons.fitness_center_outlined,
      child: Column(
        children: [
          Row(
            children: [
              const Text('Mass (kg):', style: TextStyle(fontSize: 11, color: Colors.white70)),
              const Spacer(),
              SizedBox(
                width: 70,
                child: TextFormField(
                  initialValue: rb.mass.toString(),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 11),
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  onFieldSubmitted: (v) {
                    final val = double.tryParse(v);
                    if (val != null) {
                      rb.mass = val;
                      widget.state.notifyObjectModified();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Use Gravity:', style: TextStyle(fontSize: 11, color: Colors.white70)),
              const Spacer(),
              Switch(
                value: rb.useGravity,
                onChanged: (v) {
                  setState(() => rb.useGravity = v);
                  widget.state.notifyObjectModified();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLightCard(LightComponent light) {
    return _CardWrapper(
      title: 'Light (${light.type.name})',
      icon: Icons.lightbulb_outline,
      child: Column(
        children: [
          Row(
            children: [
              const Text('Intensity:', style: TextStyle(fontSize: 11, color: Colors.white70)),
              Expanded(
                child: Slider(
                  value: light.intensity.clamp(0.0, 10.0),
                  min: 0.0,
                  max: 10.0,
                  onChanged: (v) {
                    setState(() => light.intensity = v);
                    widget.state.notifyObjectModified();
                  },
                ),
              ),
              Text(light.intensity.toStringAsFixed(1), style: const TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard(CameraComponent cam) {
    return _CardWrapper(
      title: 'Camera',
      icon: Icons.videocam_outlined,
      child: Column(
        children: [
          Row(
            children: [
              const Text('FOV:', style: TextStyle(fontSize: 11, color: Colors.white70)),
              Expanded(
                child: Slider(
                  value: cam.fieldOfView,
                  min: 20.0,
                  max: 110.0,
                  onChanged: (v) {
                    setState(() => cam.fieldOfView = v);
                    widget.state.notifyObjectModified();
                  },
                ),
              ),
              Text('${cam.fieldOfView.toInt()}°', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddComponentButton(GameObject obj) {
    return PopupMenuButton<String>(
      onSelected: (type) {
        if (type == 'rigidbody') {
          obj.addComponent(Rigidbody3D());
        } else if (type == 'mesh') {
          obj.addComponent(MeshRenderer());
        } else if (type == 'light') {
          obj.addComponent(LightComponent(type: LightType.point));
        } else if (type == 'camera') {
          obj.addComponent(CameraComponent());
        }
        setState(() {});
        widget.state.notifyObjectModified();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'rigidbody', child: Text('Add Rigidbody 3D')),
        PopupMenuItem(value: 'mesh', child: Text('Add Mesh Renderer')),
        PopupMenuItem(value: 'light', child: Text('Add Light Component')),
        PopupMenuItem(value: 'camera', child: Text('Add Camera Component')),
      ],
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.cyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 16, color: Colors.cyanAccent),
            SizedBox(width: 6),
            Text('Add Component', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          ],
        ),
      ),
    );
  }
}

class _CardWrapper extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onDelete;

  const _CardWrapper({
    required this.title,
    required this.icon,
    required this.child,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF21252B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF282C34),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: Colors.cyanAccent),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.close, size: 14, color: Colors.white38),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: child,
          ),
        ],
      ),
    );
  }
}


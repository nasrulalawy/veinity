import 'package:flutter/material.dart';
import 'package:veinity_flutter/veinity_flutter.dart';
import '../models/editor_state.dart';
import '../theme/unity_theme.dart';

/// Unity-style Hierarchy Panel with tab header, + create menu, search bar, and scene tree.
class HierarchyPanel extends StatefulWidget {
  final EditorState state;

  const HierarchyPanel({super.key, required this.state});

  @override
  State<HierarchyPanel> createState() => _HierarchyPanelState();
}

class _HierarchyPanelState extends State<HierarchyPanel> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredObjects = widget.state.scene.rootGameObjects.where((obj) {
      if (_searchQuery.isEmpty) return true;
      return obj.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: UnityTheme.panelBgDark,
        border: Border(right: BorderSide(color: UnityTheme.border, width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tab Header: [ Hierarchy ]
          Container(
            height: 26,
            color: UnityTheme.panelHeaderInactive,
            child: Row(
              children: [
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    color: UnityTheme.panelBgDark,
                    border: Border(
                      top: BorderSide(color: UnityTheme.borderLight, width: 1.0),
                      right: BorderSide(color: UnityTheme.border, width: 1.0),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Hierarchy', style: UnityTheme.headerStyle),
                ),
                const Spacer(),
                const Icon(Icons.more_vert, size: 14, color: UnityTheme.textMuted),
                const SizedBox(width: 6),
              ],
            ),
          ),

          // 2. Sub-Toolbar: [+] Button & Search Bar
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: const BoxDecoration(
              color: UnityTheme.panelHeader,
              border: Border(bottom: BorderSide(color: UnityTheme.border)),
            ),
            child: Row(
              children: [
                // Plus Dropdown
                PopupMenuButton<String>(
                  tooltip: 'Create',
                  color: UnityTheme.panelHeader,
                  onSelected: (val) => _handleCreateMenu(val),
                  itemBuilder: (context) => const [
                    PopupMenuItem(height: 22, value: 'empty', child: Text('Create Empty', style: TextStyle(fontSize: 11))),
                    PopupMenuDivider(height: 1),
                    PopupMenuItem(height: 22, value: 'cube', child: Text('3D Object > 3D Cube', style: TextStyle(fontSize: 11))),
                    PopupMenuItem(height: 22, value: 'sphere', child: Text('3D Object > 3D Sphere', style: TextStyle(fontSize: 11))),
                    PopupMenuItem(height: 22, value: 'plane', child: Text('3D Object > 3D Plane', style: TextStyle(fontSize: 11))),
                    PopupMenuDivider(height: 1),
                    PopupMenuItem(height: 22, value: 'light', child: Text('Light > Directional Light', style: TextStyle(fontSize: 11))),
                    PopupMenuItem(height: 22, value: 'camera', child: Text('Camera', style: TextStyle(fontSize: 11))),
                  ],
                  child: Container(
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: UnityTheme.buttonBg,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: UnityTheme.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 12, color: UnityTheme.textMain),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down, size: 12, color: UnityTheme.textMuted),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Search Bar
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: UnityTheme.inputBg,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: UnityTheme.inputBorder),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.search, size: 12, color: UnityTheme.textDim),
                        ),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(fontSize: 10.5, color: UnityTheme.textMain),
                            decoration: const InputDecoration(
                              hintText: 'Search...',
                              hintStyle: TextStyle(fontSize: 10.5, color: UnityTheme.textDim),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.only(bottom: 12),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Scene Root Row (▼ SampleScene)
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: UnityTheme.panelBgDark,
            child: Row(
              children: [
                const Icon(Icons.arrow_drop_down, size: 16, color: UnityTheme.textMuted),
                const SizedBox(width: 2),
                const Icon(Icons.layers, size: 13, color: UnityTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  widget.state.scene.name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: UnityTheme.textMuted),
                ),
                const Spacer(),
                const Text('★', style: TextStyle(fontSize: 9, color: UnityTheme.textDim)),
              ],
            ),
          ),

          // 4. GameObjects Tree
          Expanded(
            child: ListView.builder(
              itemCount: filteredObjects.length,
              itemBuilder: (context, index) {
                final obj = filteredObjects[index];
                final isSelected = widget.state.selectedGameObject == obj;

                return InkWell(
                  onTap: () => widget.state.selectGameObject(obj),
                  child: Container(
                    height: 20,
                    padding: const EdgeInsets.only(left: 24, right: 8),
                    color: isSelected ? UnityTheme.selectionBlue : Colors.transparent,
                    child: Row(
                      children: [
                        // Eye toggle icon
                        GestureDetector(
                          onTap: () {
                            obj.setActive(!obj.activeSelf);
                            widget.state.notifyObjectModified();
                          },
                          child: Icon(
                            obj.activeSelf ? Icons.visibility : Icons.visibility_off,
                            size: 11,
                            color: isSelected
                                ? Colors.white70
                                : (obj.activeSelf ? UnityTheme.textDim : const Color(0xFF444444)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Type Icon
                        Icon(
                          _getIconForObject(obj),
                          size: 13,
                          color: isSelected ? Colors.white : UnityTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        // Name
                        Expanded(
                          child: Text(
                            obj.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isSelected
                                  ? Colors.white
                                  : (obj.activeSelf ? UnityTheme.textMain : UnityTheme.textDim),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForObject(GameObject obj) {
    if (obj.tryGetComponent<CameraComponent>() != null) return Icons.videocam;
    if (obj.tryGetComponent<LightComponent>() != null) return Icons.lightbulb;
    if (obj.tryGetComponent<MeshRenderer>() != null) return Icons.view_in_ar;
    return Icons.widgets;
  }

  void _handleCreateMenu(String value) {
    switch (value) {
      case 'cube':
        widget.state.createGameObject('Cube', primitive: PrimitiveType.cube);
        break;
      case 'sphere':
        widget.state.createGameObject('Sphere', primitive: PrimitiveType.sphere);
        break;
      case 'plane':
        widget.state.createGameObject('Plane', primitive: PrimitiveType.plane);
        break;
      case 'light':
        final light = GameObject('Directional Light', 'Light');
        light.transform.position = Vector3(0.0, 5.0, 0.0);
        light.transform.lookAt(Vector3.zero());
        light.addComponent(LightComponent(type: LightType.directional, intensity: 1.0));
        widget.state.scene.addGameObject(light);
        widget.state.selectGameObject(light);
        break;
      case 'camera':
        final cam = GameObject('Camera', 'MainCamera');
        cam.transform.position = Vector3(0.0, 2.0, -5.0);
        cam.addComponent(CameraComponent());
        widget.state.scene.addGameObject(cam);
        widget.state.selectGameObject(cam);
        break;
      case 'empty':
        widget.state.createGameObject('GameObject');
        break;
    }
  }
}

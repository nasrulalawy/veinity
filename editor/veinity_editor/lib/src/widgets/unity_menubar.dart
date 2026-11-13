import 'package:flutter/material.dart';
import 'package:veinity_flutter/veinity_flutter.dart';
import '../models/editor_state.dart';
import '../theme/unity_theme.dart';

/// Unity-style Top Window Menubar and Main Controls Toolbar.
class UnityMenubar extends StatelessWidget {
  final EditorState state;

  const UnityMenubar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Classic Window Menu Bar (File, Edit, Assets, GameObject, etc.)
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: UnityTheme.menuBarBg,
          child: Row(
            children: [
              _buildMenuItem(context, 'File', ['New Scene', 'Open Scene', 'Save', 'Save As...', 'Build Settings...']),
              _buildMenuItem(context, 'Edit', ['Undo', 'Redo', 'Cut', 'Copy', 'Paste', 'Duplicate', 'Delete', 'Project Settings...']),
              _buildMenuItem(context, 'Assets', ['Create > C# / Dart Script', 'Create > Material', 'Import New Asset...', 'Show in Finder']),
              _buildGameObjectMenu(context),
              _buildComponentMenu(context),
              _buildMenuItem(context, 'Window', ['Panels > Hierarchy', 'Panels > Inspector', 'Panels > Scene', 'Panels > Console', 'Layouts > Default']),
              _buildMenuItem(context, 'Help', ['About Veinity Engine', 'Unity to Flutter Migration Guide', 'API Documentation']),
              const Spacer(),
              const Text(
                'Veinity 3D Engine (Flutter Edition) - Personal <DX12/Metal>',
                style: TextStyle(fontSize: 10, color: UnityTheme.textDim),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),

        // 2. Unity Main Toolbar (Tools, Pivot, Play/Pause, Layers, Layout)
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            color: UnityTheme.toolbarBg,
            border: Border(
              top: BorderSide(color: UnityTheme.borderLight, width: 0.5),
              bottom: BorderSide(color: UnityTheme.border, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              // Tool Palette (Hand, Move, Rotate, Scale, Transform)
              Container(
                height: 26,
                decoration: BoxDecoration(
                  color: UnityTheme.inputBg,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: UnityTheme.inputBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToolButton(EditorTool.hand, Icons.pan_tool_outlined, 'View Tool (Hand)'),
                    _buildToolButton(EditorTool.move, Icons.open_with, 'Move Tool (Translate)'),
                    _buildToolButton(EditorTool.rotate, Icons.refresh, 'Rotate Tool'),
                    _buildToolButton(EditorTool.scale, Icons.crop_square, 'Scale Tool'),
                    _buildToolButton(EditorTool.transform, Icons.control_camera, 'Universal Transform Tool'),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Pivot / Center Toggle
              _buildToggleChip(
                state.pivotMode == PivotMode.pivot ? 'Pivot' : 'Center',
                state.togglePivotMode,
                'Toggle Tool Handle Position (Pivot / Center)',
              ),
              const SizedBox(width: 4),

              // Global / Local Toggle
              _buildToggleChip(
                state.handleOrientation == HandleOrientation.global ? 'Global' : 'Local',
                state.toggleHandleOrientation,
                'Toggle Tool Handle Rotation (Global / Local)',
              ),

              const Spacer(),

              // Center Play Controls (Classic Unity Triplet)
              Container(
                height: 26,
                decoration: BoxDecoration(
                  color: UnityTheme.inputBg,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: UnityTheme.inputBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Play Button
                    _buildPlayButton(
                      isActive: state.isPlaying,
                      icon: Icons.play_arrow,
                      tooltip: state.isPlaying ? 'Stop Play Mode' : 'Play',
                      activeColor: UnityTheme.selectionBlue,
                      onTap: state.togglePlay,
                    ),
                    const VerticalDivider(width: 1, color: UnityTheme.border),
                    // Pause Button
                    _buildPlayButton(
                      isActive: state.isPaused,
                      icon: Icons.pause,
                      tooltip: 'Pause',
                      activeColor: UnityTheme.pauseAmber,
                      onTap: state.isPlaying ? state.togglePause : null,
                    ),
                    const VerticalDivider(width: 1, color: UnityTheme.border),
                    // Step Button
                    _buildPlayButton(
                      isActive: false,
                      icon: Icons.skip_next,
                      tooltip: 'Step 1 Frame',
                      activeColor: Colors.transparent,
                      onTap: state.isPlaying ? () => state.log('Step 1 Frame.') : null,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Layers & Layout Dropdown
              _buildSimpleDropdown('Layers', ['Default', 'TransparentFX', 'Ignore Raycast', 'Water', 'UI']),
              const SizedBox(width: 6),
              _buildSimpleDropdown('Layout', ['Default', '2 by 3', '4 Split', 'Tall', 'Wide']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, List<String> items) {
    return PopupMenuButton<String>(
      tooltip: title,
      offset: const Offset(0, 22),
      color: UnityTheme.panelHeader,
      itemBuilder: (context) => items.map((item) {
        return PopupMenuItem(
          height: 24,
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 11, color: UnityTheme.textMain)),
        );
      }).toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(title, style: const TextStyle(fontSize: 11, color: UnityTheme.textMain)),
      ),
    );
  }

  Widget _buildGameObjectMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'GameObject',
      offset: const Offset(0, 22),
      color: UnityTheme.panelHeader,
      onSelected: (val) => _handleCreateMenu(val),
      itemBuilder: (context) => const [
        PopupMenuItem(height: 24, value: 'empty', child: Text('Create Empty', style: TextStyle(fontSize: 11))),
        PopupMenuDivider(height: 1),
        PopupMenuItem(height: 24, value: 'cube', child: Text('3D Object > Cube', style: TextStyle(fontSize: 11))),
        PopupMenuItem(height: 24, value: 'sphere', child: Text('3D Object > Sphere', style: TextStyle(fontSize: 11))),
        PopupMenuItem(height: 24, value: 'plane', child: Text('3D Object > Plane', style: TextStyle(fontSize: 11))),
        PopupMenuDivider(height: 1),
        PopupMenuItem(height: 24, value: 'light', child: Text('Light > Directional Light', style: TextStyle(fontSize: 11))),
        PopupMenuItem(height: 24, value: 'camera', child: Text('Camera', style: TextStyle(fontSize: 11))),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text('GameObject', style: TextStyle(fontSize: 11, color: UnityTheme.textMain)),
      ),
    );
  }

  Widget _buildComponentMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Component',
      offset: const Offset(0, 22),
      color: UnityTheme.panelHeader,
      onSelected: (val) {
        if (state.selectedGameObject != null) {
          if (val == 'rb') state.selectedGameObject!.addComponent(Rigidbody3D());
          if (val == 'mesh') state.selectedGameObject!.addComponent(MeshRenderer());
          state.notifyObjectModified();
          state.log('Added component to ${state.selectedGameObject!.name}.');
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(height: 24, value: 'mesh', child: Text('Mesh > Mesh Renderer', style: TextStyle(fontSize: 11))),
        PopupMenuItem(height: 24, value: 'rb', child: Text('Physics > Rigidbody', style: TextStyle(fontSize: 11))),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text('Component', style: TextStyle(fontSize: 11, color: UnityTheme.textMain)),
      ),
    );
  }

  Widget _buildToolButton(EditorTool tool, IconData icon, String tooltip) {
    final isSelected = state.activeTool == tool;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => state.setTool(tool),
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? UnityTheme.selectionBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Icon(icon, size: 14, color: isSelected ? Colors.white : UnityTheme.textMuted),
        ),
      ),
    );
  }

  Widget _buildToggleChip(String label, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: UnityTheme.buttonBg,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: UnityTheme.border),
          ),
          child: Text(label, style: const TextStyle(fontSize: 10.5, color: UnityTheme.textMain)),
        ),
      ),
    );
  }

  Widget _buildPlayButton({
    required bool isActive,
    required IconData icon,
    required String tooltip,
    required Color activeColor,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 24,
          alignment: Alignment.center,
          color: isActive ? activeColor : Colors.transparent,
          child: Icon(
            icon,
            size: 16,
            color: onTap == null
                ? UnityTheme.textDim
                : (isActive ? Colors.white : UnityTheme.textMain),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleDropdown(String label, List<String> options) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: UnityTheme.buttonBg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: UnityTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: UnityTheme.textMain)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 14, color: UnityTheme.textMuted),
        ],
      ),
    );
  }

  void _handleCreateMenu(String value) {
    switch (value) {
      case 'cube':
        state.createGameObject('Cube', primitive: PrimitiveType.cube);
        break;
      case 'sphere':
        state.createGameObject('Sphere', primitive: PrimitiveType.sphere);
        break;
      case 'plane':
        state.createGameObject('Plane', primitive: PrimitiveType.plane);
        break;
      case 'light':
        final light = GameObject('Directional Light');
        light.transform.position = Vector3(0.0, 5.0, 0.0);
        light.transform.lookAt(Vector3.zero());
        light.addComponent(LightComponent(type: LightType.directional, intensity: 1.0));
        state.scene.addGameObject(light);
        state.selectGameObject(light);
        state.log('Created Directional Light.');
        break;
      case 'camera':
        final cam = GameObject('Camera');
        cam.transform.position = Vector3(0.0, 2.0, -5.0);
        cam.addComponent(CameraComponent());
        state.scene.addGameObject(cam);
        state.selectGameObject(cam);
        state.log('Created Camera.');
        break;
      case 'empty':
        state.createGameObject('GameObject');
        break;
    }
  }
}

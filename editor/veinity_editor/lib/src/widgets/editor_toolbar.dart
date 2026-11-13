import 'package:flutter/material.dart';
import 'package:veinity_flutter/veinity_flutter.dart';
import '../models/editor_state.dart';

/// Top control bar for the Veinity Editor with Play/Pause controls and GameObject creation.
class EditorToolbar extends StatelessWidget {
  final EditorState state;

  const EditorToolbar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF21252B),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          // Brand Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.token, color: Colors.cyanAccent, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'VEINITY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('3D ENGINE', style: TextStyle(fontSize: 10, color: Colors.white70)),
              ),
            ],
          ),

          const SizedBox(width: 24),

          // Add GameObject Dropdown
          PopupMenuButton<String>(
            tooltip: 'Add GameObject',
            onSelected: (value) => _handleCreateMenu(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'cube', child: Text('🧊 3D Cube')),
              const PopupMenuItem(value: 'sphere', child: Text('⚪ 3D Sphere')),
              const PopupMenuItem(value: 'plane', child: Text('⬛ 3D Plane')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'light', child: Text('💡 Directional Light')),
              const PopupMenuItem(value: 'camera', child: Text('🎥 Camera')),
              const PopupMenuItem(value: 'empty', child: Text('📦 Empty GameObject')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white70),
                  SizedBox(width: 6),
                  Text('Add Object', style: TextStyle(fontSize: 13, color: Colors.white)),
                  Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Centered Play / Pause Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF181A1F),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                // Play Button
                IconButton(
                  tooltip: state.isPlaying ? 'Stop' : 'Play',
                  icon: Icon(
                    state.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: state.isPlaying ? Colors.redAccent : Colors.greenAccent,
                    size: 22,
                  ),
                  onPressed: state.togglePlay,
                ),
                // Pause Button
                IconButton(
                  tooltip: 'Pause',
                  icon: Icon(
                    Icons.pause_rounded,
                    color: state.isPaused ? Colors.amberAccent : Colors.white38,
                    size: 20,
                  ),
                  onPressed: state.isPlaying ? state.togglePause : null,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Delete button for selected object
          if (state.selectedGameObject != null)
            IconButton(
              tooltip: 'Delete Selected (${state.selectedGameObject!.name})',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: state.deleteSelected,
            ),
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
        final light = GameObject('Point Light');
        light.transform.position = Vector3(0.0, 3.0, 0.0);
        light.addComponent(LightComponent(type: LightType.point, intensity: 2.0));
        state.scene.addGameObject(light);
        state.selectGameObject(light);
        state.log('Created Point Light.');
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

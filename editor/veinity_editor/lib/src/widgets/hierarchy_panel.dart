import 'package:flutter/material.dart';
import 'package:veinity_flutter/veinity_flutter.dart';
import '../models/editor_state.dart';

/// Hierarchy panel displaying the scene graph tree of all GameObjects.
class HierarchyPanel extends StatelessWidget {
  final EditorState state;

  const HierarchyPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2227),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF282C34),
            child: Row(
              children: [
                const Icon(Icons.account_tree_outlined, size: 16, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                const Text(
                  'HIERARCHY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '${state.scene.rootGameObjects.length} items',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),

          // Scene Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white.withValues(alpha: 0.03),
            child: Row(
              children: [
                const Icon(Icons.layers_outlined, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  state.scene.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Objects Tree List
          Expanded(
            child: ListView.builder(
              itemCount: state.scene.rootGameObjects.length,
              itemBuilder: (context, index) {
                final obj = state.scene.rootGameObjects[index];
                final isSelected = state.selectedGameObject == obj;

                return _HierarchyItem(
                  gameObject: obj,
                  isSelected: isSelected,
                  onTap: () => state.selectGameObject(obj),
                  onToggleActive: () {
                    obj.setActive(!obj.activeSelf);
                    state.notifyObjectModified();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HierarchyItem extends StatelessWidget {
  final GameObject gameObject;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;

  const _HierarchyItem({
    required this.gameObject,
    required this.isSelected,
    required this.onTap,
    required this.onToggleActive,
  });

  IconData _getIconForObject() {
    if (gameObject.tryGetComponent<CameraComponent>() != null) return Icons.videocam_outlined;
    if (gameObject.tryGetComponent<LightComponent>() != null) return Icons.lightbulb_outline;
    if (gameObject.tryGetComponent<MeshRenderer>() != null) return Icons.view_in_ar;
    return Icons.widgets_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan.withValues(alpha: 0.25) : Colors.transparent,
          border: isSelected ? Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 1) : null,
        ),
        child: Row(
          children: [
            // Active Toggle
            GestureDetector(
              onTap: onToggleActive,
              child: Icon(
                gameObject.activeSelf ? Icons.visibility : Icons.visibility_off,
                size: 15,
                color: gameObject.activeSelf ? Colors.white60 : Colors.white24,
              ),
            ),
            const SizedBox(width: 8),

            // Type Icon
            Icon(
              _getIconForObject(),
              size: 16,
              color: isSelected ? Colors.cyanAccent : Colors.white70,
            ),
            const SizedBox(width: 8),

            // Object Name
            Expanded(
              child: Text(
                gameObject.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: gameObject.activeSelf ? (isSelected ? Colors.white : Colors.white70) : Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


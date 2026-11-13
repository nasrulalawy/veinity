import 'package:flutter/material.dart';
import '../models/editor_state.dart';
import '../theme/unity_theme.dart';

/// Compact bottom status bar found at the bottom of the Unity Editor window.
class UnityStatusBar extends StatelessWidget {
  final EditorState state;

  const UnityStatusBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final latestLog = state.logs.isNotEmpty ? state.logs.last : null;
    final selected = state.selectedGameObject;

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: UnityTheme.toolbarBg,
        border: Border(top: BorderSide(color: UnityTheme.border, width: 1.0)),
      ),
      child: Row(
        children: [
          // Left: Latest console log message with icon
          Icon(
            latestLog?.type == 'error'
                ? Icons.cancel
                : (latestLog?.type == 'warning' ? Icons.warning : Icons.info_outline),
            size: 13,
            color: latestLog?.type == 'error'
                ? const Color(0xFFEF5350)
                : (latestLog?.type == 'warning' ? const Color(0xFFFFB74D) : UnityTheme.textMuted),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              latestLog?.message ?? 'Veinity 3D Engine ready.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: UnityTheme.textMuted),
            ),
          ),

          const SizedBox(width: 12),

          // Center-Right: Selected object indicator
          if (selected != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: UnityTheme.panelBgDark,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: UnityTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 11, color: UnityTheme.selectionBlue),
                  const SizedBox(width: 4),
                  Text(
                    'Selected: ${selected.name}',
                    style: const TextStyle(fontSize: 10, color: UnityTheme.textBright),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Right: Graphics API & Engine Tag
          const Text(
            'Metal / OpenGL Fallback | 60 FPS | Veinity v0.1.0-alpha',
            style: TextStyle(fontSize: 10, color: UnityTheme.textDim),
          ),
        ],
      ),
    );
  }
}

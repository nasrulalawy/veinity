import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Transform;
import 'package:flutter/scheduler.dart';
import 'package:veinity_flutter/veinity_flutter.dart';
import '../controllers/editor_camera_controller.dart';
import '../models/editor_state.dart';
import '../theme/unity_theme.dart';
import 'grid_painter.dart';

/// Unity-style Viewport supporting [Scene] View and [Game] View tabs,
/// complete with Viewport toolbar and 3D orientation gizmo.
class SceneViewport extends StatefulWidget {
  final EditorState state;

  const SceneViewport({super.key, required this.state});

  @override
  State<SceneViewport> createState() => _SceneViewportState();
}

class _SceneViewportState extends State<SceneViewport> with SingleTickerProviderStateMixin {
  late final GameLoop _gameLoop;
  late final Ticker _ticker;
  late final GameObject _editorCameraObj;
  late final EditorCameraController _cameraController;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _gameLoop = GameLoop(widget.state.scene);

    // Setup dedicated Editor Camera for Scene View
    _editorCameraObj = GameObject('Scene View Camera');
    _editorCameraObj.addComponent(CameraComponent(fieldOfView: 60.0));
    _cameraController = EditorCameraController(cameraObject: _editorCameraObj);

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (widget.state.isPlaying && !widget.state.isPaused) {
      _gameLoop.tick(dt);
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    _gameLoop.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSceneTab = widget.state.activeViewportTab == ViewportTab.scene;

    // Set appropriate active camera depending on tab
    if (isSceneTab) {
      Scene.mainCamera = _editorCameraObj.getComponent<CameraComponent>();
    } else {
      final sceneCams = widget.state.scene.findObjectsOfType<CameraComponent>();
      if (sceneCams.isNotEmpty) {
        Scene.mainCamera = sceneCams.first;
      }
    }

    return Container(
      color: UnityTheme.panelBgDark,
      child: Column(
        children: [
          // 1. Tab Bar: [ Scene ] [ Game ]
          Container(
            height: 26,
            color: UnityTheme.panelHeaderInactive,
            child: Row(
              children: [
                _buildViewportTab('Scene', ViewportTab.scene),
                _buildViewportTab('Game', ViewportTab.game),
                const Spacer(),
                const Icon(Icons.more_vert, size: 14, color: UnityTheme.textMuted),
                const SizedBox(width: 6),
              ],
            ),
          ),

          // 2. Viewport Sub-Toolbar (Shaded, 2D, Lighting, Gizmos)
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: const BoxDecoration(
              color: UnityTheme.panelHeader,
              border: Border(bottom: BorderSide(color: UnityTheme.border)),
            ),
            child: Row(
              children: [
                _buildToolbarPill('Shaded', Icons.arrow_drop_down),
                const SizedBox(width: 4),
                _buildToolbarTextButton('2D', false),
                const SizedBox(width: 4),
                _buildToolbarIconButton(Icons.lightbulb, true, 'Toggle Scene Lighting'),
                _buildToolbarIconButton(Icons.volume_up, false, 'Toggle Audio'),
                _buildToolbarIconButton(Icons.auto_awesome, true, 'Toggle Effects'),
                const Spacer(),
                _buildToolbarPill('Gizmos', Icons.arrow_drop_down),
              ],
            ),
          ),

          // 3. Main Viewport Area
          Expanded(
            child: isSceneTab ? _buildSceneView() : _buildGameView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneView() {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _cameraController.handleZoom(event.scrollDelta.dy);
          setState(() {});
        }
      },
      child: GestureDetector(
        onPanUpdate: (details) {
          _cameraController.handleOrbit(details.delta.dx, details.delta.dy);
          setState(() {});
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 3D Scene Mesh Rendering
            CustomPaint(
              painter: FlutterFallbackRenderer(scene: widget.state.scene),
              isComplex: true,
              willChange: true,
            ),

            // 3D Grid & Selection Gizmo
            CustomPaint(
              painter: GridPainter(
                scene: widget.state.scene,
                selectedObject: widget.state.selectedGameObject,
              ),
            ),

            // Iconic Unity Orientation Gizmo (Top Right Cones)
            Positioned(
              top: 12,
              right: 12,
              child: _buildUnityOrientationGizmo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: FlutterFallbackRenderer(scene: widget.state.scene),
        ),
        // Aspect Ratio Badge
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text('Free Aspect  |  Display 1 (16:9)', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ),
        ),
      ],
    );
  }

  Widget _buildViewportTab(String label, ViewportTab tab) {
    final isActive = widget.state.activeViewportTab == tab;

    return InkWell(
      onTap: () => widget.state.setViewportTab(tab),
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? UnityTheme.panelBgDark : Colors.transparent,
          border: isActive
              ? const Border(
                  top: BorderSide(color: UnityTheme.borderLight, width: 1.0),
                  right: BorderSide(color: UnityTheme.border, width: 1.0),
                )
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? UnityTheme.textBright : UnityTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarPill(String title, IconData icon) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: UnityTheme.buttonBg,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: UnityTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: UnityTheme.textMain)),
          Icon(icon, size: 12, color: UnityTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildToolbarTextButton(String title, bool active) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? UnityTheme.selectionBlue : UnityTheme.buttonBg,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: UnityTheme.border),
      ),
      child: Text(title, style: TextStyle(fontSize: 10, color: active ? Colors.white : UnityTheme.textMain)),
    );
  }

  Widget _buildToolbarIconButton(IconData icon, bool active, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 20,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? UnityTheme.buttonBg : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(icon, size: 11, color: active ? Colors.white : UnityTheme.textDim),
      ),
    );
  }

  Widget _buildUnityOrientationGizmo() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cones representation
          Positioned(
            right: 8,
            child: Text('x', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: UnityTheme.axisX)),
          ),
          Positioned(
            top: 6,
            child: Text('y', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: UnityTheme.axisY)),
          ),
          Positioned(
            left: 8,
            child: Text('z', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: UnityTheme.axisZ)),
          ),
          // Center cone
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle)),
          // Persp label
          const Positioned(
            bottom: 6,
            child: Text('Persp', style: TextStyle(fontSize: 9, color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

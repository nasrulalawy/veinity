import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Transform;
import 'package:flutter/scheduler.dart';
import 'package:veinity_flutter/veinity_flutter.dart';
import '../controllers/editor_camera_controller.dart';
import '../models/editor_state.dart';
import 'grid_painter.dart';

/// The interactive 3D Scene Viewport in the Veinity Editor.
class SceneViewport extends StatefulWidget {
  final EditorState state;

  const SceneViewport({super.key, required this.state});

  @override
  State<SceneViewport> createState() => _SceneViewportState();
}

class _SceneViewportState extends State<SceneViewport>
    with SingleTickerProviderStateMixin {
  late final GameLoop _gameLoop;
  late final Ticker _ticker;
  late final GameObject _editorCameraObj;
  late final EditorCameraController _cameraController;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _gameLoop = GameLoop(widget.state.scene);

    // Setup dedicated Editor Camera
    _editorCameraObj = GameObject('Editor Camera');
    _editorCameraObj.addComponent(CameraComponent(fieldOfView: 60.0));
    _cameraController = EditorCameraController(cameraObject: _editorCameraObj);

    // Ensure editor camera is the active scene camera
    Scene.mainCamera = _editorCameraObj.getComponent<CameraComponent>();

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

    // Only tick game scripts and physics when in Play Mode
    if (widget.state.isPlaying && !widget.state.isPaused) {
      _gameLoop.tick(dt);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _gameLoop.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _cameraController.handleZoom(event.scrollDelta.dy);
          setState(() {});
        }
      },
      child: GestureDetector(
        onPanUpdate: (details) {
          // Orbit camera on drag
          _cameraController.handleOrbit(details.delta.dx, details.delta.dy);
          setState(() {});
        },
        child: Container(
          color: const Color(0xFF181A1F),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. 3D Scene Renderer
              CustomPaint(
                painter: FlutterFallbackRenderer(scene: widget.state.scene),
                isComplex: true,
                willChange: true,
              ),

              // 2. 3D Grid & Selection Gizmo
              CustomPaint(
                painter: GridPainter(
                  scene: widget.state.scene,
                  selectedObject: widget.state.selectedGameObject,
                ),
              ),

              // 3. Top-Left Viewport Mode Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.state.isPlaying
                        ? Colors.green.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.state.isPlaying ? Colors.greenAccent : Colors.white24,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.state.isPlaying ? Icons.play_arrow : Icons.edit,
                        size: 13,
                        color: widget.state.isPlaying ? Colors.greenAccent : Colors.white70,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.state.isPlaying ? 'PLAYING' : 'EDITING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.state.isPlaying ? Colors.greenAccent : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Top-Right Navigation Hints
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Mouse Drag: Orbit  |  Scroll: Zoom',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


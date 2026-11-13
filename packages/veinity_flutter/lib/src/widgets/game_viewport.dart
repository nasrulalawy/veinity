import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:veinity_core/veinity_core.dart';
import '../input/flutter_input_bridge.dart';
import '../renderer/flutter_fallback_renderer.dart';

/// The central Flutter widget that hosts, updates, and renders a 3D Veinity Scene.
class GameViewport extends StatefulWidget {
  final Scene scene;

  /// Optional widget builder to overlay custom Flutter UI (HUD, inventory, controls)
  /// directly on top of the 3D viewport.
  final Widget Function(BuildContext context, Scene scene)? overlayBuilder;

  /// Whether this viewport should automatically request keyboard focus on mount.
  final bool autofocus;

  const GameViewport({
    super.key,
    required this.scene,
    this.overlayBuilder,
    this.autofocus = true,
  });

  @override
  State<GameViewport> createState() => _GameViewportState();
}

class _GameViewportState extends State<GameViewport>
    with SingleTickerProviderStateMixin {
  late final GameLoop _gameLoop;
  late final Ticker _ticker;
  late final FocusNode _focusNode;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _gameLoop = GameLoop(widget.scene);
    _gameLoop.start();

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

    // Advance engine tick
    _gameLoop.tick(dt);

    // Trigger repaint
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _gameLoop.stop();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        FlutterInputBridge.handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Listener(
        onPointerDown: (event) {
          _focusNode.requestFocus();
          Input.internalSetAction('Fire', true);
        },
        onPointerUp: (event) {
          Input.internalSetAction('Fire', false);
        },
        onPointerMove: (event) {
          Input.internalSetMouse(
            Vector2(event.localPosition.dx, event.localPosition.dy),
            Vector2(event.delta.dx, event.delta.dy),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 3D Viewport Rendering Canvas
            CustomPaint(
              painter: FlutterFallbackRenderer(scene: widget.scene),
              isComplex: true,
              willChange: true,
            ),

            // Optional Flutter UI Overlay on top
            if (widget.overlayBuilder != null)
              widget.overlayBuilder!(context, widget.scene),
          ],
        ),
      ),
    );
  }
}

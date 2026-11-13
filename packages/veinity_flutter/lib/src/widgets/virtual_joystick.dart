import 'package:flutter/material.dart';
import 'package:veinity_core/veinity_core.dart' hide Transform;

/// An on-screen virtual joystick widget for mobile touchscreen input.
class VirtualJoystick extends StatefulWidget {
  final double radius;
  final double stickRadius;
  final Color baseColor;
  final Color stickColor;

  const VirtualJoystick({
    super.key,
    this.radius = 60.0,
    this.stickRadius = 25.0,
    this.baseColor = const Color(0x55FFFFFF),
    this.stickColor = const Color(0xAAFFFFFF),
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _stickPosition = Offset.zero;

  void _updateStick(Offset localOffset) {
    final center = Offset(widget.radius, widget.radius);
    final delta = localOffset - center;
    final distance = delta.distance;

    final clampedDelta = distance > widget.radius
        ? (delta / distance) * widget.radius
        : delta;

    setState(() {
      _stickPosition = clampedDelta;
    });

    // Normalize to -1.0 .. 1.0
    final normalizedX = clampedDelta.dx / widget.radius;
    final normalizedY = -clampedDelta.dy / widget.radius; // Invert Y for forward

    Input.internalSetAxis(InputAxis.horizontal, normalizedX);
    Input.internalSetAxis(InputAxis.vertical, normalizedY);
  }

  void _resetStick() {
    setState(() {
      _stickPosition = Offset.zero;
    });
    Input.internalSetAxis(InputAxis.horizontal, 0.0);
    Input.internalSetAxis(InputAxis.vertical, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _updateStick(details.localPosition),
      onPanUpdate: (details) => _updateStick(details.localPosition),
      onPanEnd: (_) => _resetStick(),
      onPanCancel: () => _resetStick(),
      child: Container(
        width: widget.radius * 2,
        height: widget.radius * 2,
        decoration: BoxDecoration(
          color: widget.baseColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Center(
          child: Transform.translate(
            offset: _stickPosition,
            child: Container(
              width: widget.stickRadius * 2,
              height: widget.stickRadius * 2,
              decoration: BoxDecoration(
                color: widget.stickColor,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

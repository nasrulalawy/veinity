import 'package:meta/meta.dart';

/// Marks a component field as visible and editable in the Veinity Editor Inspector.
///
/// Example:
/// ```dart
/// class PlayerController extends Component {
///   @Inspectable(label: 'Movement Speed', min: 1.0, max: 50.0)
///   double speed = 10.0;
/// }
/// ```
@immutable
class Inspectable {
  /// Display label shown in the Inspector panel.
  final String? label;

  /// Tooltip / description shown when hovering over the property.
  final String? tooltip;

  /// Minimum value allowed (for numbers).
  final double? min;

  /// Maximum value allowed (for numbers).
  final double? max;

  /// Step increment for numeric sliders/draggers.
  final double? step;

  /// Whether the field is read-only in the editor.
  final bool readOnly;

  const Inspectable({
    this.label,
    this.tooltip,
    this.min,
    this.max,
    this.step,
    this.readOnly = false,
  });
}

/// Specifies that a component requires another component to be present on the same GameObject.
///
/// If the required component is not already attached, the engine can automatically add it.
@immutable
class RequireComponent {
  final Type requiredType;

  const RequireComponent(this.requiredType);
}

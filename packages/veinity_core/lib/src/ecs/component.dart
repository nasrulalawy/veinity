import 'package:meta/meta.dart';
import '../math/transform.dart';
import 'collision.dart';
import 'game_object.dart';

/// Base class for everything attached to [GameObject]s.
///
/// Analogous to Unity's `MonoBehaviour`.
abstract class Component {
  GameObject? _gameObject;
  bool _enabled = true;
  bool _isAwoken = false;
  bool _isStarted = false;
  bool _isDestroyed = false;

  /// The GameObject this component is attached to.
  GameObject get gameObject {
    if (_gameObject == null) {
      throw StateError('Component is not attached to any GameObject.');
    }
    return _gameObject!;
  }

  /// The Transform attached to this GameObject (shortcut for `gameObject.transform`).
  Transform get transform => gameObject.transform;

  /// Whether this component is currently enabled.
  bool get enabled => _enabled;

  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (_gameObject != null && _gameObject!.activeInHierarchy) {
      if (_enabled) {
        onEnable();
      } else {
        onDisable();
      }
    }
  }

  /// Whether this component has been destroyed.
  bool get isDestroyed => _isDestroyed;

  // --- Internal engine state hooks ---

  @internal
  void internalAttach(GameObject obj) {
    _gameObject = obj;
  }

  @internal
  void internalAwake() {
    if (_isAwoken || _isDestroyed) return;
    _isAwoken = true;
    onAwake();
    if (_enabled && gameObject.activeInHierarchy) {
      onEnable();
    }
  }

  @internal
  void internalStart() {
    if (_isStarted || !_isAwoken || _isDestroyed) return;
    _isStarted = true;
    onStart();
  }

  @internal
  void internalDestroy() {
    if (_isDestroyed) return;
    if (_enabled && gameObject.activeInHierarchy) {
      onDisable();
    }
    _isDestroyed = true;
    onDestroy();
  }

  // --- Lifecycle Callbacks ---

  /// Called once when the component instance is being loaded, before [onStart].
  @mustCallSuper
  void onAwake() {}

  /// Called whenever the component or its GameObject becomes enabled and active.
  @mustCallSuper
  void onEnable() {}

  /// Called before the first frame update only if the script is enabled.
  @mustCallSuper
  void onStart() {}

  /// Called once per frame. Use this for general gameplay logic.
  void onUpdate(double dt) {}

  /// Called once per frame after all [onUpdate] calls have finished.
  /// Ideal for camera follow or secondary updates.
  void onLateUpdate(double dt) {}

  /// Called at a fixed framerate (e.g., 50Hz) synchronized with the physics engine.
  void onFixedUpdate(double fixedDt) {}

  /// Called whenever the component or its GameObject becomes disabled.
  @mustCallSuper
  void onDisable() {}

  /// Called when the component or its GameObject is destroyed.
  @mustCallSuper
  void onDestroy() {}

  // --- Physics Callbacks ---

  /// Called when this collider/rigidbody has begun touching another rigidbody/collider.
  void onCollisionEnter(Collision3D collision) {}

  /// Called every frame this collider/rigidbody is touching another.
  void onCollisionStay(Collision3D collision) {}

  /// Called when this collider/rigidbody has stopped touching another.
  void onCollisionExit(Collision3D collision) {}

  /// Called when a Collider enters the trigger.
  void onTriggerEnter(GameObject other) {}

  /// Called every frame another Collider remains inside the trigger.
  void onTriggerStay(GameObject other) {}

  /// Called when another Collider exits the trigger.
  void onTriggerExit(GameObject other) {}

  // --- Utility Shortcuts ---

  /// Returns the component of Type [T] on this GameObject, or throws if not found.
  T getComponent<T extends Component>() => gameObject.getComponent<T>();

  /// Returns the component of Type [T] on this GameObject, or null if not found.
  T? tryGetComponent<T extends Component>() => gameObject.tryGetComponent<T>();

  /// Returns all components of Type [T] on this GameObject.
  List<T> getComponents<T extends Component>() => gameObject.getComponents<T>();

  /// Adds a new component to this GameObject.
  T addComponent<T extends Component>(T component) => gameObject.addComponent<T>(component);
}

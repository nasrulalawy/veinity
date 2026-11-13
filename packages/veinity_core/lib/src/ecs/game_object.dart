import 'package:meta/meta.dart';
import '../math/transform.dart';
import 'component.dart';
import 'scene.dart';

/// Base entity class in the Veinity Engine.
///
/// Analogous to Unity's `GameObject`. Everything in a Scene is a GameObject
/// that holds components representing its behavior, visual mesh, physics, etc.
class GameObject {
  String name;
  String tag;
  int layer;

  late final Transform transform;
  Scene? _scene;

  bool _activeSelf = true;
  bool _isDestroyed = false;

  final List<Component> _components = [];

  GameObject([this.name = 'GameObject', this.tag = 'Untagged', this.layer = 0]) {
    transform = Transform(this);
  }

  /// Whether this GameObject is locally active.
  bool get activeSelf => _activeSelf;

  /// Whether this GameObject is active in the entire hierarchy (all parents active).
  bool get activeInHierarchy {
    if (!_activeSelf || _isDestroyed) return false;
    var currentParent = transform.parent;
    while (currentParent != null) {
      if (!currentParent.gameObject.activeSelf) return false;
      currentParent = currentParent.parent;
    }
    return true;
  }

  /// The scene this GameObject belongs to.
  Scene? get scene => _scene;

  /// Whether this GameObject has been destroyed.
  bool get isDestroyed => _isDestroyed;

  /// List of all attached components.
  List<Component> get components => List.unmodifiable(_components);

  // --- Hierarchy & Activation ---

  /// Activates or deactivates the GameObject.
  void setActive(bool active) {
    if (_activeSelf == active) return;
    _activeSelf = active;

    final inHierarchy = activeInHierarchy;
    for (final comp in _components) {
      if (comp.enabled) {
        if (inHierarchy) {
          comp.onEnable();
        } else {
          comp.onDisable();
        }
      }
    }

    // Propagate state changes to children
    for (final child in transform.children) {
      if (child.gameObject._activeSelf) {
        child.gameObject._notifyHierarchyChanged(inHierarchy);
      }
    }
  }

  void _notifyHierarchyChanged(bool parentActiveInHierarchy) {
    for (final comp in _components) {
      if (comp.enabled) {
        if (parentActiveInHierarchy && _activeSelf) {
          comp.onEnable();
        } else {
          comp.onDisable();
        }
      }
    }
    for (final child in transform.children) {
      if (child.gameObject._activeSelf) {
        child.gameObject._notifyHierarchyChanged(parentActiveInHierarchy && _activeSelf);
      }
    }
  }

  // --- Component Management ---

  /// Adds a component to this GameObject.
  T addComponent<T extends Component>(T component) {
    if (_isDestroyed) {
      throw StateError('Cannot add component to a destroyed GameObject.');
    }
    component.internalAttach(this);
    _components.add(component);

    // If attached to a scene, notify scene to register lifecycle hooks
    if (_scene != null) {
      _scene!.internalRegisterComponent(component);
    }

    return component;
  }

  /// Retrieves the first component of type [T], throwing [StateError] if none exists.
  T getComponent<T extends Component>() {
    final comp = tryGetComponent<T>();
    if (comp == null) {
      throw StateError('Component of type $T not found on GameObject "$name".');
    }
    return comp;
  }

  /// Retrieves the first component of type [T], or null if not found.
  T? tryGetComponent<T extends Component>() {
    for (var i = 0; i < _components.length; i++) {
      final c = _components[i];
      if (c is T && !c.isDestroyed) {
        return c;
      }
    }
    return null;
  }

  /// Retrieves all components of type [T] on this GameObject.
  List<T> getComponents<T extends Component>() {
    final results = <T>[];
    for (var i = 0; i < _components.length; i++) {
      final c = _components[i];
      if (c is T && !c.isDestroyed) {
        results.add(c);
      }
    }
    return results;
  }

  /// Removes a component from this GameObject and destroys it.
  void removeComponent(Component component) {
    if (_components.remove(component)) {
      component.internalDestroy();
    }
  }

  // --- Destruction ---

  /// Marks this GameObject for destruction at the end of the current frame.
  void destroy() {
    if (_isDestroyed) return;
    _isDestroyed = true;

    // Destroy all components
    for (final comp in _components) {
      comp.internalDestroy();
    }

    // Recursively destroy children
    for (final child in transform.children) {
      child.gameObject.destroy();
    }

    if (_scene != null) {
      _scene!.internalMarkForDestroy(this);
    }
  }

  // --- Internal Scene Binding ---

  @internal
  void internalSetScene(Scene? newScene) {
    _scene = newScene;
    if (newScene != null) {
      for (final comp in _components) {
        newScene.internalRegisterComponent(comp);
      }
    }
  }

  // --- Static Global Search Helpers ---

  /// Finds the first GameObject in the active scene with the given [name].
  static GameObject? find(String name) => Scene.activeScene?.find(name);

  /// Finds all GameObjects in the active scene with the given [tag].
  static List<GameObject> findWithTag(String tag) =>
      Scene.activeScene?.findWithTag(tag) ?? const [];

  /// Finds the first GameObject in the active scene with the given [tag].
  static GameObject? findGameObjectWithTag(String tag) =>
      Scene.activeScene?.findGameObjectWithTag(tag);

  /// Destroys the specified [gameObject].
  static void destroyObject(GameObject gameObject) => gameObject.destroy();
}

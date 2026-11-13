import 'package:meta/meta.dart';
import '../components/camera.dart';
import 'component.dart';
import 'game_object.dart';

/// Represents a 3D game level, scene, or world containing GameObjects.
class Scene {
  static Scene? activeScene;

  /// The active primary camera in the scene.
  static CameraComponent? mainCamera;

  final String name;
  final List<GameObject> _rootGameObjects = [];

  final List<Component> _awakeQueue = [];
  final List<Component> _startQueue = [];
  final List<Component> _allComponents = [];
  final List<GameObject> _pendingDestroy = [];

  Scene(this.name) {
    activeScene ??= this;
  }

  /// List of all top-level GameObjects in this scene.
  List<GameObject> get rootGameObjects => List.unmodifiable(_rootGameObjects);

  /// Sets this scene as the globally active scene.
  void makeActive() {
    activeScene = this;
  }

  // --- GameObject Addition / Removal ---

  /// Adds a GameObject to this scene.
  void addGameObject(GameObject gameObject) {
    if (gameObject.scene != null && gameObject.scene != this) {
      gameObject.scene!.removeGameObject(gameObject);
    }

    if (gameObject.transform.parent == null) {
      if (!_rootGameObjects.contains(gameObject)) {
        _rootGameObjects.add(gameObject);
      }
    }

    gameObject.internalSetScene(this);
  }

  /// Removes a GameObject from this scene.
  void removeGameObject(GameObject gameObject) {
    _rootGameObjects.remove(gameObject);
    gameObject.internalSetScene(null);
  }

  // --- Component Registration ---

  @internal
  void internalRegisterComponent(Component component) {
    if (!_allComponents.contains(component)) {
      _allComponents.add(component);
      _awakeQueue.add(component);
    }
  }

  @internal
  void internalMarkForDestroy(GameObject gameObject) {
    if (!_pendingDestroy.contains(gameObject)) {
      _pendingDestroy.add(gameObject);
    }
  }

  // --- Search Queries ---

  /// Finds a GameObject by name anywhere in this scene.
  GameObject? find(String name) {
    for (final root in _rootGameObjects) {
      final found = _searchByName(root, name);
      if (found != null) return found;
    }
    return null;
  }

  GameObject? _searchByName(GameObject current, String targetName) {
    if (current.name == targetName && !current.isDestroyed) {
      return current;
    }
    for (final child in current.transform.children) {
      final found = _searchByName(child.gameObject, targetName);
      if (found != null) return found;
    }
    return null;
  }

  /// Finds all GameObjects matching the given [tag].
  List<GameObject> findWithTag(String tag) {
    final results = <GameObject>[];
    for (final root in _rootGameObjects) {
      _searchByTag(root, tag, results);
    }
    return results;
  }

  void _searchByTag(GameObject current, String tag, List<GameObject> results) {
    if (current.tag == tag && !current.isDestroyed) {
      results.add(current);
    }
    for (final child in current.transform.children) {
      _searchByTag(child.gameObject, tag, results);
    }
  }

  /// Finds the first GameObject matching [tag].
  GameObject? findGameObjectWithTag(String tag) {
    for (final root in _rootGameObjects) {
      final found = _searchFirstByTag(root, tag);
      if (found != null) return found;
    }
    return null;
  }

  GameObject? _searchFirstByTag(GameObject current, String tag) {
    if (current.tag == tag && !current.isDestroyed) return current;
    for (final child in current.transform.children) {
      final found = _searchFirstByTag(child.gameObject, tag);
      if (found != null) return found;
    }
    return null;
  }

  /// Finds all components of type [T] across the scene.
  List<T> findObjectsOfType<T extends Component>() {
    final list = <T>[];
    for (var i = 0; i < _allComponents.length; i++) {
      final c = _allComponents[i];
      if (c is T && !c.isDestroyed) {
        list.add(c);
      }
    }
    return list;
  }

  // --- Frame Lifecycle Execution ---

  /// Executes standard frame lifecycle (Awake, Start, Update, LateUpdate, Cleanup).
  void update(double dt) {
    _processAwakeQueue();
    _processStartQueue();

    // 1. Update cycle
    for (var i = 0; i < _allComponents.length; i++) {
      final comp = _allComponents[i];
      if (comp.enabled && comp.gameObject.activeInHierarchy && !comp.isDestroyed) {
        comp.onUpdate(dt);
      }
    }

    // 2. Late Update cycle
    for (var i = 0; i < _allComponents.length; i++) {
      final comp = _allComponents[i];
      if (comp.enabled && comp.gameObject.activeInHierarchy && !comp.isDestroyed) {
        comp.onLateUpdate(dt);
      }
    }

    // 3. Flush destroyed objects
    _flushPendingDestroys();
  }

  /// Executes fixed physics lifecycle.
  void fixedUpdate(double fixedDt) {
    for (var i = 0; i < _allComponents.length; i++) {
      final comp = _allComponents[i];
      if (comp.enabled && comp.gameObject.activeInHierarchy && !comp.isDestroyed) {
        comp.onFixedUpdate(fixedDt);
      }
    }
  }

  void _processAwakeQueue() {
    if (_awakeQueue.isEmpty) return;
    final processing = List<Component>.from(_awakeQueue);
    _awakeQueue.clear();

    for (var i = 0; i < processing.length; i++) {
      final comp = processing[i];
      if (!comp.isDestroyed) {
        comp.internalAwake();
        _startQueue.add(comp);
      }
    }
  }

  void _processStartQueue() {
    if (_startQueue.isEmpty) return;
    final processing = List<Component>.from(_startQueue);
    _startQueue.clear();

    for (var i = 0; i < processing.length; i++) {
      final comp = processing[i];
      if (comp.enabled && comp.gameObject.activeInHierarchy && !comp.isDestroyed) {
        comp.internalStart();
      } else if (!comp.isDestroyed) {
        // Keep in start queue until it becomes active and enabled
        _startQueue.add(comp);
      }
    }
  }

  void _flushPendingDestroys() {
    if (_pendingDestroy.isEmpty) return;

    for (final obj in _pendingDestroy) {
      if (obj.transform.parent != null) {
        obj.transform.parent = null;
      }
      _rootGameObjects.remove(obj);
    }
    _pendingDestroy.clear();

    _allComponents.removeWhere((c) => c.isDestroyed);
    _awakeQueue.removeWhere((c) => c.isDestroyed);
    _startQueue.removeWhere((c) => c.isDestroyed);
  }
}


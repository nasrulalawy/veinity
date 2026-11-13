import 'package:flutter/material.dart';
import 'src/models/editor_state.dart';
import 'src/widgets/console_panel.dart';
import 'src/widgets/editor_toolbar.dart';
import 'src/widgets/hierarchy_panel.dart';
import 'src/widgets/inspector_panel.dart';
import 'src/widgets/scene_viewport.dart';

void main() {
  runApp(const VeinityEditorApp());
}

class VeinityEditorApp extends StatelessWidget {
  const VeinityEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veinity 3D Game Engine Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF181A1F),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          surface: Color(0xFF1E2227),
        ),
      ),
      home: const EditorHomeScreen(),
    );
  }
}

class EditorHomeScreen extends StatefulWidget {
  const EditorHomeScreen({super.key});

  @override
  State<EditorHomeScreen> createState() => _EditorHomeScreenState();
}

class _EditorHomeScreenState extends State<EditorHomeScreen> {
  late final EditorState _editorState;

  @override
  void initState() {
    super.initState();
    _editorState = EditorState();
    _editorState.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _editorState.removeListener(_onStateChanged);
    _editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 1. Top Control Bar (Toolbar)
          EditorToolbar(state: _editorState),

          // 2. Middle Main Workspace (Hierarchy | Viewport | Inspector)
          Expanded(
            child: Row(
              children: [
                // Left Panel: Scene Hierarchy
                HierarchyPanel(state: _editorState),

                // Center Viewport: 3D Scene View & Interactive Gizmo
                Expanded(
                  child: SceneViewport(state: _editorState),
                ),

                // Right Panel: Property Inspector
                InspectorPanel(state: _editorState),
              ],
            ),
          ),

          // 3. Bottom Panel (Console & Project Assets)
          ConsolePanel(state: _editorState),
        ],
      ),
    );
  }
}

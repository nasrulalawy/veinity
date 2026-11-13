import 'package:flutter/material.dart';
import '../models/editor_state.dart';
import '../theme/unity_theme.dart';

/// Unity-style Project & Console bottom panel with two-column folder tree and log view.
class ProjectConsolePanel extends StatefulWidget {
  final EditorState state;

  const ProjectConsolePanel({super.key, required this.state});

  @override
  State<ProjectConsolePanel> createState() => _ProjectConsolePanelState();
}

class _ProjectConsolePanelState extends State<ProjectConsolePanel> {
  int _activeTab = 0; // 0: Project, 1: Console
  String _selectedFolder = 'Scenes';
  double _iconScale = 55.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        color: UnityTheme.panelBgDark,
        border: Border(top: BorderSide(color: UnityTheme.border, width: 1.0)),
      ),
      child: Column(
        children: [
          // 1. Tab Bar: [ Project ] [ Console ]
          Container(
            height: 26,
            color: UnityTheme.panelHeaderInactive,
            child: Row(
              children: [
                _buildTab('Project', 0),
                _buildTab('Console', 1),
                const Spacer(),
                const Icon(Icons.more_vert, size: 14, color: UnityTheme.textMuted),
                const SizedBox(width: 6),
              ],
            ),
          ),

          // 2. Tab Content
          Expanded(
            child: _activeTab == 0 ? _buildProjectTab() : _buildConsoleTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _activeTab == index;

    return InkWell(
      onTap: () => setState(() => _activeTab = index),
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

  Widget _buildProjectTab() {
    return Row(
      children: [
        // Left Column: Folders Tree
        Container(
          width: 180,
          decoration: const BoxDecoration(
            color: UnityTheme.panelBgDark,
            border: Border(right: BorderSide(color: UnityTheme.border)),
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              _buildFolderItem('Assets', Icons.folder, isRoot: true),
              _buildFolderItem('Materials', Icons.folder, indent: 18),
              _buildFolderItem('Models', Icons.folder, indent: 18),
              _buildFolderItem('Prefabs', Icons.folder, indent: 18),
              _buildFolderItem('Scenes', Icons.folder, indent: 18),
              _buildFolderItem('Scripts', Icons.folder, indent: 18),
              _buildFolderItem('Textures', Icons.folder, indent: 18),
            ],
          ),
        ),

        // Right Column: Assets Grid + Breadcrumbs + Icon Slider
        Expanded(
          child: Column(
            children: [
              // Breadcrumb bar
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: UnityTheme.panelHeader,
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 12, color: UnityTheme.textDim),
                    const SizedBox(width: 4),
                    Text('Assets > $_selectedFolder', style: const TextStyle(fontSize: 10.5, color: UnityTheme.textMuted)),
                    const Spacer(),
                    // Unity Icon Size Slider
                    SizedBox(
                      width: 80,
                      child: SliderTheme(
                        data: SliderThemeData(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4)),
                        child: Slider(
                          value: _iconScale,
                          min: 35.0,
                          max: 80.0,
                          activeColor: UnityTheme.textMuted,
                          inactiveColor: UnityTheme.border,
                          onChanged: (v) => setState(() => _iconScale = v),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Asset items
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _getAssetsForFolder(_selectedFolder),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFolderItem(String name, IconData icon, {bool isRoot = false, double indent = 4}) {
    final isSelected = _selectedFolder == name;

    return InkWell(
      onTap: () => setState(() => _selectedFolder = name),
      child: Container(
        height: 20,
        padding: EdgeInsets.only(left: indent, right: 6),
        color: isSelected ? UnityTheme.selectionBlue : Colors.transparent,
        child: Row(
          children: [
            Icon(Icons.arrow_drop_down, size: 14, color: isSelected ? Colors.white70 : UnityTheme.textMuted),
            Icon(icon, size: 13, color: isSelected ? Colors.white : const Color(0xFFF0B342)),
            const SizedBox(width: 5),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : UnityTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getAssetsForFolder(String folder) {
    if (folder == 'Scenes') {
      return [
        _buildAssetIcon('SampleScene.scene', Icons.layers, const Color(0xFF4DB6AC)),
        _buildAssetIcon('Level01_Playground.scene', Icons.layers, const Color(0xFF4DB6AC)),
        _buildAssetIcon('MainMenu.scene', Icons.layers, const Color(0xFF4DB6AC)),
      ];
    } else if (folder == 'Scripts') {
      return [
        _buildAssetIcon('PlayerController.dart', Icons.code, const Color(0xFF4FC3F7)),
        _buildAssetIcon('RotateCollectible.dart', Icons.code, const Color(0xFF4FC3F7)),
        _buildAssetIcon('ThirdPersonCamera.dart', Icons.code, const Color(0xFF4FC3F7)),
        _buildAssetIcon('GameManager.dart', Icons.code, const Color(0xFF4FC3F7)),
        _buildAssetIcon('CoinTrigger.dart', Icons.code, const Color(0xFF4FC3F7)),
      ];
    } else if (folder == 'Materials') {
      return [
        _buildAssetIcon('Player_Blue.mat', Icons.blur_circular, const Color(0xFF42A5F5)),
        _buildAssetIcon('Ground_Grid.mat', Icons.blur_circular, const Color(0xFF78909C)),
        _buildAssetIcon('Gem_Glow.mat', Icons.blur_circular, const Color(0xFFFFCA28)),
        _buildAssetIcon('Pillar_Stone.mat', Icons.blur_circular, const Color(0xFFB0BEC5)),
        _buildAssetIcon('Skybox_Atmosphere.mat', Icons.blur_circular, const Color(0xFF5C6BC0)),
      ];
    } else if (folder == 'Prefabs') {
      return [
        _buildAssetIcon('Player.prefab', Icons.inventory_2, const Color(0xFF42A5F5)),
        _buildAssetIcon('Pillar_Column.prefab', Icons.inventory_2, const Color(0xFF42A5F5)),
        _buildAssetIcon('Gem_Pickup.prefab', Icons.inventory_2, const Color(0xFF42A5F5)),
        _buildAssetIcon('Platform.prefab', Icons.inventory_2, const Color(0xFF42A5F5)),
      ];
    } else if (folder == 'Models') {
      return [
        _buildAssetIcon('character_mesh.fbx', Icons.view_in_ar, const Color(0xFF81C784)),
        _buildAssetIcon('pillar_column.glb', Icons.view_in_ar, const Color(0xFF81C784)),
        _buildAssetIcon('gem_diamond.gltf', Icons.view_in_ar, const Color(0xFF81C784)),
        _buildAssetIcon('hover_platform.obj', Icons.view_in_ar, const Color(0xFF81C784)),
      ];
    } else if (folder == 'Textures') {
      return [
        _buildAssetIcon('floor_grid_albedo.png', Icons.image, const Color(0xFFAB47BC)),
        _buildAssetIcon('pillar_stone_normal.png', Icons.image, const Color(0xFFAB47BC)),
        _buildAssetIcon('gem_glow_emissive.png', Icons.image, const Color(0xFFAB47BC)),
      ];
    }
    return [
      _buildAssetIcon('Materials', Icons.folder, const Color(0xFFF0B342)),
      _buildAssetIcon('Models', Icons.folder, const Color(0xFFF0B342)),
      _buildAssetIcon('Prefabs', Icons.folder, const Color(0xFFF0B342)),
      _buildAssetIcon('Scenes', Icons.folder, const Color(0xFFF0B342)),
      _buildAssetIcon('Scripts', Icons.folder, const Color(0xFFF0B342)),
      _buildAssetIcon('Textures', Icons.folder, const Color(0xFFF0B342)),
    ];
  }

  Widget _buildAssetIcon(String label, IconData icon, Color iconColor) {
    return SizedBox(
      width: _iconScale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconScale * 0.55, color: iconColor),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: UnityTheme.textMain),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleTab() {
    return Column(
      children: [
        // Sub-toolbar: Clear, Collapse, Clear on Play
        Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: UnityTheme.panelHeader,
          child: Row(
            children: [
              _buildConsoleButton('Clear', widget.state.clearLogs),
              const SizedBox(width: 6),
              _buildConsoleToggle('Collapse', false),
              const SizedBox(width: 4),
              _buildConsoleToggle('Clear on Play', true),
              const Spacer(),
              const Icon(Icons.info_outline, size: 12, color: Colors.white70),
              const SizedBox(width: 2),
              Text('${widget.state.logs.length}', style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),

        // Log items
        Expanded(
          child: ListView.builder(
            itemCount: widget.state.logs.length,
            itemBuilder: (context, index) {
              final log = widget.state.logs[index];
              final isEven = index % 2 == 0;

              return Container(
                height: 20,
                color: isEven ? UnityTheme.panelBgDark : UnityTheme.panelBg,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 12, color: Color(0xFF4FC3F7)),
                    const SizedBox(width: 6),
                    Text(
                      '[${log.timeString}] ${log.message}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: UnityTheme.textMain),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConsoleButton(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: UnityTheme.buttonBg,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: UnityTheme.border),
        ),
        child: Text(title, style: const TextStyle(fontSize: 10, color: UnityTheme.textMain)),
      ),
    );
  }

  Widget _buildConsoleToggle(String title, bool active) {
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
}

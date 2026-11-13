import 'package:flutter/material.dart';
import '../models/editor_state.dart';

/// Bottom panel displaying Console logs and Project Asset Browser tabs.
class ConsolePanel extends StatefulWidget {
  final EditorState state;

  const ConsolePanel({super.key, required this.state});

  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends State<ConsolePanel> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2227),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          // Tab Header Bar
          Container(
            height: 32,
            color: const Color(0xFF282C34),
            child: Row(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.cyanAccent,
                  labelColor: Colors.cyanAccent,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'CONSOLE'),
                    Tab(text: 'PROJECT ASSETS'),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Clear Console',
                  icon: const Icon(Icons.block, size: 14, color: Colors.white38),
                  onPressed: widget.state.clearLogs,
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Console Tab
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: widget.state.logs.length,
                  itemBuilder: (context, index) {
                    final log = widget.state.logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 13, color: Colors.cyanAccent),
                          const SizedBox(width: 8),
                          Text(
                            log,
                            style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Project Assets Tab
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _buildAssetFolder('Scenes', Icons.layers_outlined),
                      const SizedBox(width: 12),
                      _buildAssetFolder('Models', Icons.view_in_ar),
                      const SizedBox(width: 12),
                      _buildAssetFolder('Scripts', Icons.code),
                      const SizedBox(width: 12),
                      _buildAssetFolder('Textures', Icons.image_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetFolder(String name, IconData icon) {
    return Container(
      width: 80,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.cyanAccent.withValues(alpha: 0.7)),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}

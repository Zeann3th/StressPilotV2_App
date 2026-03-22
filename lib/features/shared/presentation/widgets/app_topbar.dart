import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'dart:io';

import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';

class AppTopBar extends StatefulWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchSubmitted;

  const AppTopBar({super.key, this.searchController, this.onSearchSubmitted});

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar> {
  @override
  Widget build(BuildContext context) {
    final keymap = context.watch<KeymapProvider>();
    final bg = AppColors.surface;
    final border = AppColors.border;

    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.br16,
        border: Border.all(color: border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [

          const Spacer(),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: SizedBox(
              height: 36,
              child: PilotInput(
                controller: widget.searchController,
                onSubmitted: widget.onSearchSubmitted,
                placeholder: 'Search projects, endpoints...',
                prefixIcon: Icons.search_rounded,
              ),
            ),
          ),

          const Spacer(),

          _TopBarIcon(
            icon: LucideIcons.sparkles,
            tooltip: 'AI Agent',
            onTap: () => AppNavigator.pushNamed(AppRouter.agentRoute),
          ),
          const SizedBox(width: 8),
          _TopBarIcon(
            icon: LucideIcons.shoppingBag,
            tooltip: 'Marketplace',
            onTap: () => AppNavigator.pushNamed(AppRouter.marketplaceRoute),
          ),
          const SizedBox(width: 8),
          _TopBarIcon(
            icon: LucideIcons.settings,
            tooltip: _tip('Settings', keymap.getShortcut('app.settings')),
            onTap: () => AppNavigator.pushNamed(AppRouter.settingsRoute),
          ),
          const SizedBox(width: 8),

          GestureDetector(
            onTapDown: (tap) async {
              final renderBox = context.findRenderObject() as RenderBox?;
              final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
              final pos = renderBox?.localToGlobal(tap.globalPosition) ?? tap.globalPosition;
              final selected = await showMenu<String>(
                context: context,
                position: RelativeRect.fromLTRB(pos.dx, pos.dy, overlay.size.width - pos.dx, overlay.size.height - pos.dy),
                items: const [
                  PopupMenuItem(value: 'profile', child: Text('Profile')),
                  PopupMenuItem(value: 'exit', child: Text('Exit')),
                ],
              );

              if (selected == 'exit') {

                try {
                  await getIt<ProcessManager>().forceKill();
                } catch (_) {}
                exit(0);
              }
            },
            child: _TopBarIcon(
              icon: LucideIcons.user,
              tooltip: 'Profile',
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  String _tip(String label, String? shortcut) {
    if (shortcut == null || shortcut.isEmpty) return label;
    return '$label ($shortcut)';
  }
}

class _TopBarIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TopBarIcon({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_TopBarIcon> createState() => _TopBarIconState();
}

class _TopBarIconState extends State<_TopBarIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent;
    final accentHover = AppColors.accentHover;

    final iconColor = _isHovered ? accentHover : AppColors.textSecondary;

    return ShadTooltip(
      builder: (context) => Text(widget.tooltip),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppDurations.micro,
            width: 44,
            height: 40,
            decoration: BoxDecoration(
              color: _isHovered
                  ? accent.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: AppRadius.br8,
            ),
            child: Icon(widget.icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}

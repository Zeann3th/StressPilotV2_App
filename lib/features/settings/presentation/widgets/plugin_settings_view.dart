import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/settings/presentation/provider/plugin_settings_provider.dart';
import 'package:stress_pilot/features/marketplace/domain/models/plugin_descriptor.dart';

class PluginSettingsView extends StatefulWidget {
  const PluginSettingsView({super.key});

  @override
  State<PluginSettingsView> createState() => _PluginSettingsViewState();
}

class _PluginSettingsViewState extends State<PluginSettingsView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      await context.read<PluginSettingsProvider>().loadPlugins();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PluginSettingsProvider>();
    final plugins = provider.plugins;
    final selected = provider.selectedPlugin;
    final border = AppColors.border;

    if (provider.isLoading && plugins.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [

        Container(
          width: 300,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: border.withValues(alpha: 0.1))),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text('Plugins', style: AppTypography.label.copyWith(fontSize: 16)),
                    const Spacer(),
                    PilotButton.ghost(
                      icon: Icons.refresh_rounded,
                      onPressed: () async {
                        await context.read<PluginSettingsProvider>().reloadAllPlugins();
                        if (context.mounted) {
                          PilotToast.show(context, 'All plugins reloaded');
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: plugins.length,
                  itemBuilder: (context, index) {
                    final plugin = plugins[index];
                    final isSelected = selected?.pluginId == plugin.pluginId;
                    return _PluginListTile(
                      plugin: plugin,
                      isSelected: isSelected,
                      onTap: () => provider.selectPlugin(plugin),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: selected == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.extension_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('Select a plugin to view details', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : _PluginDetailView(plugin: selected),
        ),
      ],
    );
  }
}

class _PluginListTile extends StatelessWidget {
  final PluginDescriptor plugin;
  final bool isSelected;
  final VoidCallback onTap;

  const _PluginListTile({
    required this.plugin,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent;
    final textColor = AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.05))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plugin.pluginId,
                    style: AppTypography.body.copyWith(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'v${plugin.version}',
                  style: AppTypography.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plugin.provider ?? 'Unknown Author',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PluginDetailView extends StatelessWidget {
  final PluginDescriptor plugin;

  const _PluginDetailView({required this.plugin});

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary;
    final secondaryColor = AppColors.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: AppRadius.br12,
                ),
                child: Icon(Icons.extension_rounded, size: 32, color: AppColors.accent),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plugin.pluginId, style: AppTypography.heading.copyWith(fontSize: 24)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('v${plugin.version}', style: AppTypography.body.copyWith(color: secondaryColor)),
                        const SizedBox(width: 12),
                        Text('by ${plugin.provider ?? "Unknown"}', style: AppTypography.body.copyWith(color: AppColors.accent)),
                      ],
                    ),
                  ],
                ),
              ),
              PilotButton.primary(
                label: 'Reload',
                icon: Icons.refresh_rounded,
                onPressed: () async {
                  await context.read<PluginSettingsProvider>().reloadPlugin(plugin.pluginId);
                  if (context.mounted) {
                    PilotToast.show(context, 'Plugin reloaded');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          _Section(
            title: 'Description',
            content: Text(
              plugin.pluginDescription ?? 'No description provided.',
              style: AppTypography.body.copyWith(color: textColor, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Information',
            content: Column(
              children: [
                _InfoRow(label: 'Plugin ID', value: plugin.pluginId),
                _InfoRow(label: 'Version', value: plugin.version),
                _InfoRow(label: 'Provider', value: plugin.provider ?? 'Unknown'),
                _InfoRow(label: 'License', value: plugin.license ?? 'Unknown'),
                _InfoRow(label: 'Class', value: plugin.pluginClass ?? 'Unknown'),
                _InfoRow(label: 'Requires', value: plugin.requires ?? 'Any'),
              ],
            ),
          ),
          if (plugin.dependencies.isNotEmpty) ...[
            const SizedBox(height: 24),
            _Section(
              title: 'Dependencies',
              content: Column(
                children: plugin.dependencies.map((d) => _InfoRow(
                  label: d.pluginId,
                  value: d.version ?? 'Any',
                  isDependency: true,
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.label.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        content,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDependency;

  const _InfoRow({required this.label, required this.value, this.isDependency = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                color: isDependency ? AppColors.accent : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

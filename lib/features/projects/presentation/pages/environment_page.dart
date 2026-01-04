import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/common/presentation/widgets/environment_table.dart';

class EnvironmentPage extends StatefulWidget {
  final int environmentId;
  final String projectName;

  const EnvironmentPage({
    super.key,
    required this.environmentId,
    required this.projectName,
  });

  @override
  State<EnvironmentPage> createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends State<EnvironmentPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnvironmentProvider>().loadVariables(widget.environmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        scrolledUnderElevation: 0,
        title: Text(
          "Environment: ${widget.projectName}",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: colors.onSurface,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.outlineVariant),
        ),
        actions: [
          _SaveButton(environmentId: widget.environmentId),
          const SizedBox(width: 16),
        ],
      ),
      body: const EnvironmentTable(),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final int environmentId;
  const _SaveButton({required this.environmentId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnvironmentProvider>();
    final hasChanges = provider.hasChanges;

    return FilledButton.icon(
      onPressed: hasChanges && !provider.isLoading
          ? () async {
              try {
                await provider.saveChanges(environmentId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Changes saved successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          : null,
      icon: provider.isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.save, size: 18),
      label: const Text('Save Changes'),
    );
  }
}

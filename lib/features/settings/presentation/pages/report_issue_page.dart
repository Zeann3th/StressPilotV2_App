import 'package:flutter/material.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/config/app_config.dart';

class ReportIssuePage extends StatefulWidget {
  final String? error;
  final String? stack;

  const ReportIssuePage({super.key, this.error, this.stack});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _titleCtrl = TextEditingController();
  final _replicateCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _replicateCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) {
      PilotToast.show(context, 'Please enter a title', isError: true);
      return;
    }

    final version = AppConfig.version;
    final replicate = _replicateCtrl.text.trim();
    final details = '''
### Environment
- **Version:** $version

### Steps to Reproduce
${replicate.isEmpty ? 'N/A' : replicate}

### Error Details
```
${widget.error ?? 'No error message'}
```

### Stack Trace
```
${widget.stack ?? 'No stack trace available'}
```
''';

    final uri = Uri.parse(AppConfig.githubIssuesUrl).replace(queryParameters: {
      'title': _titleCtrl.text.trim(),
      'body': details,
    });

    AppNavigator.pushNamed(
      AppRouter.githubWebviewRoute,
      arguments: {'url': uri.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.background;
    final surface = AppColors.surface;
    final textCol = AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                PilotButton.ghost(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Text(
                  'Report Issue',
                  style: AppTypography.heading.copyWith(color: textCol),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: AppRadius.br12,
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Issue Title *', style: AppTypography.label),
                    const SizedBox(height: 8),
                    PilotInput(
                      controller: _titleCtrl,
                      placeholder: 'Brief summary of the issue',
                    ),
                    const SizedBox(height: 24),
                    Text('How to Replicate', style: AppTypography.label),
                    const SizedBox(height: 8),
                    PilotInput(
                      controller: _replicateCtrl,
                      placeholder: 'Steps to reproduce the crash...',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 24),
                    Text('Attached Error Data', style: AppTypography.label),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.elevated,
                        borderRadius: AppRadius.br8,
                      ),
                      child: Text(
                        widget.error ?? 'No error data attached',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PilotButton.ghost(
                          label: 'Cancel',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        PilotButton.primary(
                          label: 'Continue to GitHub',
                          icon: Icons.open_in_new_rounded,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

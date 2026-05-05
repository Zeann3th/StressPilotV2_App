import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/endpoints/presentation/widgets/key_value_editor.dart';

class EndpointEditorTabs extends StatelessWidget {
  final TabController tabController;
  final Map<String, String> params;
  final Map<String, String> headers;
  final String body;
  final TextEditingController successConditionController;
  final Map<String, String> variables;
  final ValueChanged<Map<String, String>> onParamsChanged;
  final ValueChanged<Map<String, String>> onHeadersChanged;
  final ValueChanged<String> onBodyChanged;
  final ValueChanged<Map<String, String>> onVariablesChanged;
  final ScrollController? paramsScrollCtrl;
  final ScrollController? headersScrollCtrl;
  final ScrollController? bodyScrollCtrl;
  final ScrollController? settingsScrollCtrl;

  const EndpointEditorTabs({
    super.key,
    required this.tabController,
    required this.params,
    required this.headers,
    required this.body,
    required this.successConditionController,
    required this.variables,
    required this.onParamsChanged,
    required this.onHeadersChanged,
    required this.onBodyChanged,
    required this.onVariablesChanged,
    this.paramsScrollCtrl,
    this.headersScrollCtrl,
    this.bodyScrollCtrl,
    this.settingsScrollCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.baseBackground;
    final textColor = AppColors.textPrimary;
    final secondaryText = AppColors.textSecondary;
    final border = AppColors.divider;

    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: TabBar(
            controller: tabController,
            isScrollable: false, // Use full width
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: AppColors.accent,
            indicatorWeight: 2,
            dividerColor: Colors.transparent,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: const [
              Tab(text: 'Params'),
              Tab(text: 'Headers'),
              Tab(text: 'Body'),
              Tab(text: 'Configuration'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              // Params
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: KeyValueEditor(
                  data: params,
                  onChanged: onParamsChanged,
                  controller: paramsScrollCtrl,
                ),
              ),
              // Headers
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: KeyValueEditor(
                  data: headers,
                  onChanged: onHeadersChanged,
                  controller: headersScrollCtrl,
                ),
              ),
              // Body (Integrated PilotJsonEditor)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PilotJsonEditor(
                  initialValue: body,
                  onChanged: onBodyChanged,
                  hintText: 'Request Body (JSON)',
                ),
              ),
              // Configuration (Spaced Out as requested)
              _buildConfigurationTab(textColor, secondaryText, border),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationTab(Color textColor, Color secondaryText, Color border) {
    return ListView(
      controller: settingsScrollCtrl,
      padding: const EdgeInsets.all(24), // Increased padding
      children: [
        Text('Success Condition (SpEL)', 
          style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 12),
        PilotInput(
          controller: successConditionController,
          placeholder: 'e.g., #statusCode == 200 && #body.status == "OK"',
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        Text('Available variables: #statusCode, #body, #headers, #responseTime',
            style: AppTypography.caption.copyWith(color: secondaryText)),
        
        const SizedBox(height: 40), // More space between sections
        
        Text('Run Variables', 
          style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: KeyValueEditor(
            data: variables,
            onChanged: onVariablesChanged,
            controller: settingsScrollCtrl,
          ),
        ),
        const SizedBox(height: 12),
        Text('Extract values from response into flow-level variables.',
            style: AppTypography.caption.copyWith(color: secondaryText)),
      ],
    );
  }
}

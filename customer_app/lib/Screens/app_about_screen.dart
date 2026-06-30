import 'package:flutter/material.dart';

import 'package:ecom/constants.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';

class AppAboutScreen extends StatelessWidget {
  const AppAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(appName, style: AppTypography.displayMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('v1.0.0', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xl),
          Text(introParagraph, style: AppTypography.body),
        ],
      ),
    );
  }
}

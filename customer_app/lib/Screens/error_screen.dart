import 'package:flutter/material.dart';

import 'package:ecom/widgets/empty_state.dart';

/// Fallback screen shown for unrecognised routes.
class ErrorScreem extends StatelessWidget {
  const ErrorScreem({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Page not found',
        message: 'The page you are looking for does not exist.',
        actionLabel: 'Go home',
        onAction: () => Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (_) => false),
      ),
    );
  }
}

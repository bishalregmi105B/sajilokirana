import 'package:flutter/material.dart';

import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_button.dart';

/// Three-step onboarding shown before the login screen on first launch.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      icon: Icons.storefront_rounded,
      title: 'Local shops,\ndigitally.',
      body:
          'Order from your favourite kirana pasal and get groceries delivered '
          'in minutes — straight from your neighbourhood.',
    ),
    _OnboardPage(
      icon: Icons.electric_bolt_rounded,
      title: 'Fast & reliable.',
      body: 'Our dispatch system finds the nearest shop that has your items in '
          'stock, so you never wait for something that isn\'t there.',
    ),
    _OnboardPage(
      icon: Icons.track_changes_rounded,
      title: 'Track in real time.',
      body: 'Watch your order travel from the shop to your door on a live map. '
          'Know exactly when it arrives.',
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/'),
                child: Text('Skip',
                    style:
                        AppTypography.body.copyWith(color: AppColors.primary)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (p) => setState(() => _page = p),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.primary : AppColors.border,
                    borderRadius: AppRadius.pillBorder,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppButton(
                label: _page == _pages.length - 1 ? 'Get started' : 'Next',
                isFullWidth: true,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: AppRadius.cardBorder,
            ),
            child: Icon(icon, size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            style: AppTypography.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            body,
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

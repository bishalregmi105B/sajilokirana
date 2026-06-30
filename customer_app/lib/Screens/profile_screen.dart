import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ecom/constants.dart';
import 'package:ecom/Services/Providers/auth.provider.dart';
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_card.dart';
import 'package:ecom/widgets/app_list_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?['name'] as String? ?? 'My Account';
    final phone = user?['phone'] as String? ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── User header ────────────────────────────────────────────────
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surfaceTint,
                  child: Text(
                    initial,
                    style: AppTypography.headline.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.bodyLarge),
                    Text(phone.isNotEmpty ? phone : 'No phone',
                        style: AppTypography.caption),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Quick actions ──────────────────────────────────────────────
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickAction(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Wallet',
                  onTap: () {},
                ),
                _QuickAction(
                  icon: Icons.headset_mic_outlined,
                  label: 'Support',
                  onTap: () {},
                ),
                _QuickAction(
                  icon: Icons.payment_outlined,
                  label: 'Payments',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── My information ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.sm, bottom: AppSpacing.xs),
            child: Text('YOUR INFORMATION', style: AppTypography.caption),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppListTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Your Orders',
                  onTap: () => Navigator.of(context).pushNamed('/orders'),
                ),
                AppListTile(
                  icon: Icons.location_on_outlined,
                  title: 'Address Book',
                  onTap: () => Navigator.of(context).pushNamed('/user/address'),
                ),
                AppListTile(
                  icon: Icons.local_offer_outlined,
                  title: 'Coupons',
                  onTap: () => Navigator.of(context).pushNamed('/coupons'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Others ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.sm, bottom: AppSpacing.xs),
            child: Text('OTHERS', style: AppTypography.caption),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppListTile(
                  icon: Icons.share_outlined,
                  title: 'Share the app',
                  onTap: () => Share.share(
                    'Shop from your local kirana on $appName!',
                    subject: appName,
                  ),
                ),
                AppListTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About $appName',
                  onTap: () => Navigator.of(context).pushNamed('/app/about'),
                ),
                AppListTile(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  isDestructive: true,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to place orders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            child: Text(
              'Log out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: AppRadius.cardBorder,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

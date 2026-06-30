import 'package:flutter/material.dart';

import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_card.dart';
import 'package:ecom/widgets/empty_state.dart';

/// Notifications screen — order status updates, offers, system alerts.
/// Route: /notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notif> _notifs = [
    _Notif(
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.success,
      title: 'Order delivered',
      body: 'Your order #A1B2 was delivered successfully.',
      time: '2 hrs ago',
      read: false,
    ),
    _Notif(
      icon: Icons.local_offer_outlined,
      iconColor: AppColors.accent,
      title: 'New coupon available!',
      body: 'Use DASHAIN10 for 10% off this festive season.',
      time: 'Yesterday',
      read: true,
    ),
    _Notif(
      icon: Icons.storefront_outlined,
      iconColor: AppColors.primary,
      title: 'Shop confirmed your order',
      body: 'Shrestha General Store confirmed order #C3D4.',
      time: '2 days ago',
      read: true,
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _notifs) {
        n.read = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifs.where((n) => !n.read).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: AppTypography.body.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: _notifs.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              message:
                  "You're all caught up! Order status updates will appear here.",
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _notifs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) => _NotifTile(
                notif: _notifs[i],
                onTap: () => setState(() => _notifs[i].read = true),
              ),
            ),
    );
  }
}

class _Notif {
  _Notif({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  bool read;
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notif, required this.onTap});
  final _Notif notif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      background: notif.read ? AppColors.surface : AppColors.surfaceTint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: notif.iconColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.cardBorder,
            ),
            child: Icon(notif.icon, color: notif.iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(notif.title,
                          style: notif.read
                              ? AppTypography.body
                              : AppTypography.bodyLarge),
                    ),
                    if (!notif.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(notif.body,
                    style: AppTypography.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Text(notif.time, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

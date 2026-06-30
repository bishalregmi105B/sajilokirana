import 'package:flutter/material.dart';

import 'package:ecom/services/address_service.dart';
import 'package:ecom/Services/Exceptions/api_exception.dart';
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_button.dart';
import 'package:ecom/widgets/app_card.dart';
import 'package:ecom/widgets/app_text_field.dart';
import 'package:ecom/widgets/empty_state.dart';
import 'package:ecom/widgets/loading_shimmer.dart';

class UserAddressScreen extends StatefulWidget {
  const UserAddressScreen({super.key});

  @override
  State<UserAddressScreen> createState() => _UserAddressScreenState();
}

class _UserAddressScreenState extends State<UserAddressScreen> {
  final _service = AddressService.instance;
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final list = await _service.fetchAddresses();
      if (mounted) setState(() { _addresses = list; _isLoading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not load addresses'; _isLoading = false; });
    }
  }

  Future<void> _setDefault(String id) async {
    try {
      await _service.setDefault(id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update default address')),
      );
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteAddress(id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove address')),
      );
    }
  }

  void _showAddDialog() {
    final line1Ctrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Kathmandu');
    final labelCtrl = TextEditingController(text: 'Home');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.xl,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add new address', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(controller: labelCtrl, hintText: 'Label (Home/Work)', textInputAction: TextInputAction.next),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(controller: line1Ctrl, hintText: 'Street / Ward / Landmark', textInputAction: TextInputAction.next),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(controller: cityCtrl, hintText: 'City', textInputAction: TextInputAction.done),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Save Address',
              isFullWidth: true,
              onPressed: () async {
                if (line1Ctrl.text.trim().isEmpty) return;
                Navigator.of(ctx).pop();
                try {
                  await _service.addAddress({
                    'label': labelCtrl.text.trim().isEmpty ? 'Home' : labelCtrl.text.trim(),
                    'line1': line1Ctrl.text.trim(),
                    'city': cityCtrl.text.trim().isEmpty ? 'Kathmandu' : cityCtrl.text.trim(),
                    'lat': 27.7172,
                    'lng': 85.3240,
                    'isDefault': _addresses.isEmpty,
                  });
                  await _load();
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save address')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      body: _isLoading
          ? LoadingShimmer.list()
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: AppTypography.body.copyWith(color: AppColors.error)),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(label: 'Retry', onPressed: _load),
                  ],
                ))
              : _addresses.isEmpty
                  ? EmptyState(
                      icon: Icons.location_off_outlined,
                      title: 'No addresses yet',
                      message: 'Add a delivery address to get started.',
                      actionLabel: 'Add address',
                      onAction: _showAddDialog,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _addresses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          final a = _addresses[i];
                          final id = a['id'] as String;
                          final isDefault = a['isDefault'] as bool? ?? false;
                          return AppCard(
                            child: Row(
                              children: [
                                Icon(
                                  isDefault ? Icons.home_rounded : Icons.location_on_outlined,
                                  color: isDefault ? AppColors.primary : AppColors.textMuted,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(a['label'] as String? ?? 'Address', style: AppTypography.label),
                                          if (isDefault) ...[
                                            const SizedBox(width: AppSpacing.xs),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceTint,
                                                borderRadius: AppRadius.pillBorder,
                                              ),
                                              child: Text('Default', style: AppTypography.caption.copyWith(color: AppColors.primary)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(a['line1'] as String? ?? '', style: AppTypography.body),
                                      Text(a['city'] as String? ?? '', style: AppTypography.caption),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'default') _setDefault(id);
                                    if (v == 'delete') _delete(id);
                                  },
                                  itemBuilder: (_) => [
                                    if (!isDefault)
                                      const PopupMenuItem(value: 'default', child: Text('Set as default')),
                                    const PopupMenuItem(value: 'delete', child: Text('Remove')),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/colors.dart';

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Icon(icon, color: AppColors.primary),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center),
    ]));
  }
}

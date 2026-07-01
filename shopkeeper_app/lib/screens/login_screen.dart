import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';
import '../constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    final phone = '$appDialCode${_phoneCtrl.text.trim()}';
    if (_phoneCtrl.text.trim().length < 8) { setState(() => _error = 'Enter a valid phone number'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final cooldown = await context.read<AuthProvider>().requestOtp(phone);
      if (!mounted) return;
      if (cooldown != null && cooldown > 0) { setState(() => _error = 'Wait ${cooldown}s'); }
      else { Navigator.of(context).pushNamed('/otp', arguments: phone); }
    } catch (e) { setState(() => _error = 'Failed to send OTP'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.storefront_rounded, size: 72, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text('SajiloKirana', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary), textAlign: TextAlign.center),
        const Text('Shopkeeper Portal', style: TextStyle(fontSize: 16, color: AppColors.textMuted), textAlign: TextAlign.center),
        const SizedBox(height: 48),
        TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone number', prefixText: '$appDialCode '), keyboardType: TextInputType.phone),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
        const SizedBox(height: 16),
        FilledButton(onPressed: _loading ? null : _sendOtp, child: _loading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface))
          : const Text('Send OTP')),
      ],
    ))));
  }
}

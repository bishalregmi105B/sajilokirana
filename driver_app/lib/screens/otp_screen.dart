import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _verify() async {
    if (_codeController.text.trim().length < 4) {
      setState(() => _error = 'Enter the OTP code');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthProvider>().verifyOtp(widget.phone, _codeController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      setState(() => _error = 'Invalid or expired code');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enter the code sent to ${widget.phone}', style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'OTP Code', hintText: '123456'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
            ),
            if (_error != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _verify,
              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface)) : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}

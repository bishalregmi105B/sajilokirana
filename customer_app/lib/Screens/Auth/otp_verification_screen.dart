import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ecom/Services/Providers/auth.provider.dart';
import 'package:ecom/Services/Exceptions/api_exception.dart';
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_button.dart';
import 'package:ecom/widgets/app_text_field.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key, this.data});

  /// The full phone number (with dial code) passed from LoginScreen.
  final dynamic data;

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  late TextEditingController _otpController;
  int _secondsRemaining = 30;
  late Timer _timer;
  bool _isLoading = false;

  String get _phone => widget.data?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _startTimer();
  }

  Future<void> _verifyOTP() async {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.verifyOtp(_phone, code);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not verify. Check your connection.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _resendOtp() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.requestOtp(_phone);
      _startTimer();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resend OTP. Try again.')),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Enter the OTP', style: AppTypography.headline),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _phone.isNotEmpty ? 'Sent to $_phone' : 'Sent to your phone',
                style: AppTypography.body.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppTextField(
                controller: _otpController,
                hintText: '123456',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Verify & Continue',
                isFullWidth: true,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _verifyOTP,
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: _secondsRemaining > 0
                    ? Text(
                        'Resend OTP in ${_secondsRemaining}s',
                        style: AppTypography.caption,
                      )
                    : AppButton(
                        label: 'Resend OTP',
                        variant: AppButtonVariant.text,
                        onPressed: _resendOtp,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'package:ecom/constants.dart';
import 'package:ecom/Services/Providers/auth.provider.dart';
import 'package:ecom/Services/Exceptions/api_exception.dart';
import 'package:ecom/theme/app_colors.dart';
import 'package:ecom/theme/app_spacing.dart';
import 'package:ecom/theme/app_typography.dart';
import 'package:ecom/widgets/app_button.dart';
import 'package:ecom/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final cooldown = await auth.requestOtp(
        '$appDialCode${_phoneController.text.trim()}',
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (cooldown != null && cooldown > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Please wait ${cooldown}s before requesting another OTP.')),
        );
        return;
      }
      Navigator.of(context).pushNamed(
        '/otp/verify',
        arguments: '$appDialCode${_phoneController.text.trim()}',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Could not connect to server. Check your connection.'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 220,
                child: Lottie.asset(
                  "Assets/auth.json",
                  controller: _animCtrl,
                  onLoaded: (comp) {
                    _animCtrl
                      ..duration = comp.duration
                      ..repeat();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: ClipRRect(
                  borderRadius: AppRadius.cardBorder,
                  child: Image.asset("Assets/splash2.png", height: 52),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  appName,
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  "Your neighbourhood kirana, delivered.",
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text("Enter your phone number", style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Form(
                key: _formKey,
                child: AppTextField(
                  controller: _phoneController,
                  hintText: "98XXXXXXXX",
                  prefixText: "$appDialCode ",
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Please enter your phone number";
                    }
                    if (v.trim().length < 9) {
                      return "Enter a valid phone number";
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: "Send OTP",
                isFullWidth: true,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _requestOtp,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  "By continuing, you agree to our Terms & Privacy Policy",
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

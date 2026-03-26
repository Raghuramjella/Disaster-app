import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .forgotPassword(_emailCtrl.text.trim());
      setState(() => _codeSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).resetPassword(
            _emailCtrl.text.trim(),
            _codeCtrl.text.trim(),
            _newPasswordCtrl.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully! Please log in.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 32,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reset Your Password',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _codeSent
                          ? 'Enter the 6-digit code sent to your email'
                          : 'Enter your registered email to receive a reset code',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_codeSent) ...[
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: Form(
                  key: _emailFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        label: 'Registered Email',
                        prefixIcon: Icons.email_outlined,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Email is required';
                          }
                          if (!val.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2E7D32),
                              ),
                            )
                          : CustomButton(
                              label: 'Send Reset Code',
                              onPressed: _sendCode,
                            ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Email sent confirmation banner
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        color: Color(0xFF2E7D32),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Code sent to your email',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Check your inbox for ${_emailCtrl.text.trim()}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: Form(
                  key: _resetFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        label: 'Reset Code',
                        prefixIcon: Icons.pin_outlined,
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Reset code is required';
                          }
                          if (val.length != 6) {
                            return 'Code must be 6 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'New Password',
                        prefixIcon: Icons.lock_outline,
                        controller: _newPasswordCtrl,
                        obscureText: _obscureNew,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'New password is required';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Confirm New Password',
                        prefixIcon: Icons.lock_outline,
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (val) {
                          if (val != _newPasswordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2E7D32),
                              ),
                            )
                          : CustomButton(
                              label: 'Reset Password',
                              onPressed: _resetPassword,
                            ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() {
                          _codeSent = false;
                          _codeCtrl.clear();
                          _newPasswordCtrl.clear();
                          _confirmPasswordCtrl.clear();
                        }),
                        child: const Text(
                          'Request a new code',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

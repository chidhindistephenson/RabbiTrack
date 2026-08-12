import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_repository.dart';
import 'auth_error_messages.dart';
import 'auth_scaffold.dart';
import 'auth_validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSaving = false;
  String? _error;
  bool _showApiStatusAction = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (_formKey.currentState?.validate() != true || email.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
      _showApiStatusAction = false;
    });

    try {
      await ref.read(authRepositoryProvider).forgotPassword(email: email);

      if (mounted) {
        context.go('/reset-password?email=${Uri.encodeComponent(email)}');
      }
    } on DioException catch (error) {
      setState(() {
        _error = passwordResetErrorMessage(error);
        _showApiStatusAction = isAuthConnectionProblem(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset ',
      accent: 'Password',
      subtitle: 'We will send a reset code to your email',
      footer: AuthFooterLink(
        text: 'Remembered it? ',
        action: 'Log in',
        onPressed: () => context.go('/login'),
      ),
      children: [
        Form(
          key: _formKey,
          child: AuthTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: emailValidator,
          ),
        ),
        const SizedBox(height: 18),
        AuthPrimaryButton(
          label: 'Send code',
          isLoading: _isSaving,
          onPressed: _submit,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Color(0xFFFF8A80))),
          if (_showApiStatusAction) ...[
            const SizedBox(height: 8),
            AuthApiStatusButton(onPressed: () => context.push('/api-status')),
          ],
        ],
      ],
    );
  }
}

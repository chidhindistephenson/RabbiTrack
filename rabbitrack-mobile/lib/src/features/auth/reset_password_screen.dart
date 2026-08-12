import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_error_messages.dart';
import 'auth_repository.dart';
import 'auth_scaffold.dart';
import 'auth_validators.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSaving = false;
  String? _error;
  bool _showApiStatusAction = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
      _showApiStatusAction = false;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            email: widget.email,
            code: _codeController.text,
            password: _passwordController.text,
            passwordConfirmation: _confirmPasswordController.text,
          );

      if (mounted) {
        context.go('/login');
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
      title: 'Create ',
      accent: 'Password',
      subtitle: 'Enter the reset code sent to your email',
      footer: AuthFooterLink(
        text: 'Need another code? ',
        action: 'Send again',
        onPressed: () => context.go('/forgot-password'),
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                controller: _codeController,
                label: 'Reset code',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: resetCodeValidator,
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _passwordController,
                label: 'New password',
                icon: Icons.key,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                validator: passwordValidator,
                suffix: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF6FA27B),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    confirmPasswordValidator(value, _passwordController.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AuthPrimaryButton(
          label: 'Save password',
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

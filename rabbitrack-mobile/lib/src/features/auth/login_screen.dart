import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';
import 'auth_error_messages.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController(
    text: 'owner@rabbitrack.local',
  );
  final _passwordController = TextEditingController(text: 'secret-password');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .login(
          login: _loginController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState.hasValue && authState.value != null) {
      context.go('/farms');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.valueOrNull != null) {
        context.go('/farms');
      }
    });

    final authState = ref.watch(authControllerProvider);
    final error = authState.error;
    final showApiStatusAction = error != null && isAuthConnectionProblem(error);

    return AuthScaffold(
      title: 'Welcome ',
      accent: 'Back',
      subtitle: "Let's continue your farm journey",
      footer: AuthFooterLink(
        text: 'New here? ',
        action: 'Create an account',
        onPressed: () => context.go('/signup'),
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                controller: _loginController,
                label: 'Email, username, or phone',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.key,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: Color(0xFFF6F5EF)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AuthPrimaryButton(
                label: 'Continue',
                isLoading: authState.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            loginErrorMessage(error),
            style: const TextStyle(color: Color(0xFFFF8A80)),
          ),
          if (showApiStatusAction) ...[
            const SizedBox(height: 8),
            AuthApiStatusButton(onPressed: () => context.push('/api-status')),
          ],
        ],
        const SizedBox(height: 30),
        const SocialAuthButtons(label: 'or login with'),
      ],
    );
  }
}

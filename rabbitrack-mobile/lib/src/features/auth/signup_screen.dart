import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';
import 'auth_error_messages.dart';
import 'auth_scaffold.dart';
import 'auth_validators.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _farmController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _farmController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          farmName: _farmController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        );

    if (!mounted) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState.hasValue && authState.value != null) {
      context.go('/farms');
    }
  }

  Future<void> _signupWithGoogle() async {
    await ref.read(authControllerProvider.notifier).loginWithGoogle();

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
    final authState = ref.watch(authControllerProvider);
    final error = authState.error;
    final showApiStatusAction = error != null && isAuthConnectionProblem(error);

    return AuthScaffold(
      title: 'Create ',
      accent: 'Account',
      subtitle: "Let's start your farm journey",
      footer: AuthFooterLink(
        text: 'Already have an account? ',
        action: 'Log in',
        onPressed: () => context.go('/login'),
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: (value) => requiredTextValidator(value, 'Required'),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Required'
                    : emailValidator(value),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _farmController,
                label: 'Farm name',
                icon: Icons.home_work_outlined,
                textInputAction: TextInputAction.next,
                validator: (value) => requiredTextValidator(value, 'Required'),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.key,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
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
                validator: (value) => value == null || value.isEmpty
                    ? 'Required'
                    : passwordValidator(value),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    confirmPasswordValidator(value, _passwordController.text),
              ),
              const SizedBox(height: 18),
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
            signupErrorMessage(error),
            style: const TextStyle(color: Color(0xFFFF8A80)),
          ),
          if (showApiStatusAction) ...[
            const SizedBox(height: 8),
            AuthApiStatusButton(onPressed: () => context.push('/api-status')),
          ],
        ],
        const SizedBox(height: 30),
        SocialAuthButtons(
          label: 'or signup with',
          isLoading: authState.isLoading,
          onGooglePressed: _signupWithGoogle,
        ),
      ],
    );
  }
}

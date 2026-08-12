import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/rabbitrack_colors.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.accent,
    required this.subtitle,
    required this.children,
    required this.footer,
  });

  final String title;
  final String accent;
  final String subtitle;
  final List<Widget> children;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: RabbiTrackColors.forestGreen,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _AuthBackdrop()),
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/rabbittrack_app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'RabbiTrack',
                      style: textTheme.titleLarge?.copyWith(
                        color: RabbiTrackColors.cream,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 70),
                RichText(
                  text: TextSpan(
                    style: textTheme.headlineMedium?.copyWith(
                      color: RabbiTrackColors.cream,
                      fontWeight: FontWeight.w900,
                      height: 1.02,
                    ),
                    children: [
                      TextSpan(text: title),
                      TextSpan(
                        text: accent,
                        style: const TextStyle(color: RabbiTrackColors.warmTan),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: RabbiTrackColors.mintGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 44),
                ...children,
                const SizedBox(height: 28),
                footer,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        color: RabbiTrackColors.forestGreen,
        fontWeight: FontWeight.w700,
      ),
      cursorColor: RabbiTrackColors.warmTan,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(
          color: RabbiTrackColors.sageGreen,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: RabbiTrackColors.sageGreen, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: RabbiTrackColors.cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: RabbiTrackColors.warmTan),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
      ),
      validator: validator,
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: RabbiTrackColors.warmTan,
          foregroundColor: RabbiTrackColors.forestGreen,
          disabledBackgroundColor: RabbiTrackColors.sageGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: RabbiTrackColors.forestGreen,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: RabbiTrackColors.sageGreen)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                style: const TextStyle(
                  color: RabbiTrackColors.mintGreen,
                  fontSize: 12,
                ),
              ),
            ),
            const Expanded(child: Divider(color: RabbiTrackColors.sageGreen)),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _SocialCircle(label: 'G'),
            SizedBox(width: 22),
            _SocialCircle(label: 'f'),
            SizedBox(width: 22),
            _SocialCircle(icon: Icons.apple),
          ],
        ),
      ],
    );
  }
}

class _SocialCircle extends StatelessWidget {
  const _SocialCircle({this.label, this.icon});

  final String? label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: RabbiTrackColors.cream,
      ),
      child: Center(
        child: icon == null
            ? Text(
                label!,
                style: const TextStyle(
                  color: RabbiTrackColors.forestGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Icon(icon, color: RabbiTrackColors.forestGreen, size: 28),
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.text,
    required this.action,
    required this.onPressed,
  });

  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(color: RabbiTrackColors.mintGreen),
          children: [
            TextSpan(
              text: action,
              style: const TextStyle(
                color: RabbiTrackColors.cream,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthApiStatusButton extends StatelessWidget {
  const AuthApiStatusButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.wifi_tethering_outlined),
      label: const Text('Check API status'),
      style: TextButton.styleFrom(
        foregroundColor: RabbiTrackColors.cream,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AuthBackdropPainter());
  }
}

class _AuthBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = RabbiTrackColors.sageGreen.withValues(alpha: 0.16)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              RabbiTrackColors.sageGreen.withValues(alpha: 0.32),
              RabbiTrackColors.forestGreen.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.18, size.height * 0.08),
              radius: size.width * 0.75,
            ),
          );

    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

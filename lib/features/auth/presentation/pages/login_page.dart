import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/constants/env.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../../../../core/utils/snackbar.dart';
import '../../../../../core/utils/validators.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      context.go('/');
    } else {
      final err = ref.read(authControllerProvider).error;
      showAppSnackBar(context, handleError(err ?? '').message, isError: true);
    }
  }

  Future<void> _google() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      context.go('/');
    } else {
      final err = ref.read(authControllerProvider).error;
      showAppSnackBar(context, handleError(err ?? '').message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo Box
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderSubtleColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.directions_car_filled_rounded,
                            size: 40,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title & Subtitle
                    Text(
                      'Auto em Dia',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sua garagem inteligente, em dia.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Email Input
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.email,
                      style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: 'seu@email.com',
                        prefixIcon: const Icon(
                          Icons.mail_outline_rounded,
                          size: 20,
                          color: AppTheme.textMutedColor,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderSubtleColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      validator: Validators.password,
                      style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: AppTheme.textMutedColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppTheme.textMutedColor,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderSubtleColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Esqueceu a senha?',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Entrar',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider "ou"
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: AppTheme.borderSubtleColor, thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ou',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textMutedColor,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: AppTheme.borderSubtleColor, thickness: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google Login Button
                    OutlinedButton(
                      onPressed: (loading || !Env.isGoogleSignInConfigured) ? null : _google,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.textPrimaryColor,
                        side: const BorderSide(color: AppTheme.borderSubtleColor),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoogleLogoIcon(),
                          const SizedBox(width: 12),
                          Text(
                            'Continuar com Google',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!Env.isGoogleSignInConfigured)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Login com Google ficará disponível após a configuração.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Footer Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ainda não tem conta? ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/signup'),
                          child: Text(
                            'Criar conta',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final center = Offset(w / 2, h / 2);

    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Blue arc + bar
    paintStroke.color = const Color(0xFF4285F4);
    canvas.drawArc(rect.deflate(2), -0.5, 1.2, false, paintStroke);
    canvas.drawLine(Offset(center.dx, center.dy), Offset(w - 2, center.dy), paintStroke);

    // Green arc
    paintStroke.color = const Color(0xFF34A853);
    canvas.drawArc(rect.deflate(2), 0.7, 1.3, false, paintStroke);

    // Yellow arc
    paintStroke.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect.deflate(2), 2.0, 1.3, false, paintStroke);

    // Red arc
    paintStroke.color = const Color(0xFFEA4335);
    canvas.drawArc(rect.deflate(2), 3.3, 1.3, false, paintStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

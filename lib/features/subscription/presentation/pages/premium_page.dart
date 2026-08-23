import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/utils/snackbar.dart';
import '../../../../../shared/providers/analytics_provider.dart';
import '../../../../../shared/widgets/app_top_bar.dart';
import '../../data/subscription_repository.dart';
import '../controllers/subscription_controller.dart';

class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  bool _isAnnual = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).premiumScreenViewed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(subscriptionProvider).value ?? false;
    final productsAsync = ref.watch(subscriptionProductsProvider);
    final loading = ref.watch(subscriptionControllerProvider).isLoading;

    const priceAnnual = 'R\$ 79,90';
    const priceMonthly = 'R\$ 9,90';
    final selectedPrice = _isAnnual ? priceAnnual : priceMonthly;
    final billingText = _isAnnual ? 'Cobrado anualmente' : 'Cobrado mensalmente';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const AppTopBar(title: 'Mais', showProfile: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // Hero Visual Box
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderSubtleColor),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // High Tech Grid Pattern Graphic
                  CustomPaint(
                    painter: _TechBackgroundPainter(),
                  ),
                  // Glowing Diamond Icon
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.diamond_outlined,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Header Copy
            Text(
              'Tenha o controle completo do seu carro.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Desbloqueie recursos avançados e mantenha seu veículo sempre em dia.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textMutedColor,
              ),
            ),
            const SizedBox(height: 24),

            if (isPremium) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 40, color: AppTheme.successColor),
                    const SizedBox(height: 10),
                    Text(
                      'Você é um assinante Premium!',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aproveite todos os recursos ilimitados.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => _confirmCancel(context),
                      child: const Text('Gerenciar assinatura'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Plan Selector Toggle (Anual vs Mensal)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHighColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSubtleColor),
                ),
                child: Row(
                  children: [
                    // Anual Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAnnual = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isAnnual ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: _isAnnual
                                ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3))
                                : null,
                            boxShadow: _isAnnual
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Anual (R\$ 79,90)',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: _isAnnual ? FontWeight.w700 : FontWeight.w500,
                                  color: _isAnnual ? AppTheme.primaryColor : AppTheme.textMutedColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ECONOMIZE 30%',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppTheme.tertiaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Mensal Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAnnual = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: !_isAnnual ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: !_isAnnual
                                ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3))
                                : null,
                            boxShadow: !_isAnnual
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Mensal (R\$ 9,90)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: !_isAnnual ? FontWeight.w700 : FontWeight.w500,
                                color: !_isAnnual ? AppTheme.primaryColor : AppTheme.textMutedColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Benefits Bento Grid
              _BenefitCard(
                icon: Icons.manage_accounts_outlined,
                title: 'Múltiplos Veículos',
                description: 'Cadastre até 5 carros na mesma conta e gerencie tudo em um só lugar.',
              ),
              const SizedBox(height: 12),
              _BenefitCard(
                icon: Icons.insights_rounded,
                title: 'Relatórios Detalhados',
                description: 'Gráficos de gastos, consumo e previsão de manutenção futura.',
              ),
              const SizedBox(height: 12),
              _BenefitCard(
                icon: Icons.history_rounded,
                title: 'Histórico Ilimitado',
                description: 'Acesse todos os registros e comprovantes de serviços realizados.',
              ),
              const SizedBox(height: 24),

              // Summary & Checkout Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total a pagar hoje',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textMutedColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedPrice,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          billingText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.tertiaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // CTA Button
                    Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () => _handleSubscribe(productsAsync.value ?? []),
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
                                    'Assinar Premium',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 10),
                    Text(
                      'Cancele a qualquer momento nas configurações.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscribe(List<ProductDetails> products) async {
    final targetId = _isAnnual ? 'premium_anual' : 'premium_mensal';
    final product = products.where((p) => p.id == targetId).firstOrNull;

    if (product != null) {
      final ok = await ref.read(subscriptionControllerProvider.notifier).buy(product);
      if (mounted) {
        showAppSnackBar(
          context,
          ok ? 'Assinatura iniciada!' : 'Não foi possível concluir a compra.',
          isError: !ok,
        );
      }
    } else {
      showAppSnackBar(
        context,
        'Plano ${_isAnnual ? "Anual" : "Mensal"} selecionado. Conectando com a Google Play Store...',
      );
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar assinatura'),
        content: const Text(
          'O cancelamento é gerenciado pelo Google Play. Deseja abrir a assinatura na Play Store?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(analyticsServiceProvider).subscriptionCancelled();
            },
            child: const Text('Abrir Play Store'),
          ),
        ],
      ),
    );
  }
}

/// Benefit Card Bento
class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtleColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textMutedColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tech background lines painter
class _TechBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    final w = size.width;
    final h = size.height;

    for (double x = 0; x < w; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
    }
    for (double y = 0; y < h; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }

    final accentPaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(0, h * 0.7), Offset(w * 0.3, h), accentPaint);
    canvas.drawLine(Offset(w * 0.7, 0), Offset(w, h * 0.3), accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

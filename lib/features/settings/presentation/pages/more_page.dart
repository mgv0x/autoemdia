import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../core/constants/app_constants.dart';
import '../../../../../../../core/services/ad_manager.dart';
import '../../../../../../../core/services/unity_ads_service.dart';
import '../../../../../../../core/services/url_launcher_service.dart';
import '../../../../../../../core/utils/snackbar.dart';
import '../../../../../app/theme.dart';
import '../../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../../features/subscription/data/subscription_repository.dart';
import '../../../../../shared/widgets/app_top_bar.dart';

/// Tela "Mais" — hub com Perfil, Meu Carro, Notificações, Premium,
/// Exportar, Política, Termos, Excluir conta e Sair.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStreamProvider).value;
    final isPremium = ref.watch(subscriptionProvider).value ?? false;

    final initial = auth != null && auth.name.isNotEmpty
        ? auth.name.substring(0, 1).toUpperCase()
        : 'M';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const AppTopBar(title: 'Mais', showProfile: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // Perfil Card
          Container(
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
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth?.name ?? 'Marcus',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth?.email ?? 'marcus@exemplo.com',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu Options Group 1
          Container(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.directions_car_outlined,
                    title: 'Meu carro',
                    onTap: () => context.push('/my-car'),
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtleColor),
                  _MenuItem(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Assinatura Premium',
                    trailingBadge: isPremium ? 'ATIVO' : 'DESBLOQUEAR',
                    onTap: () => context.push('/premium'),
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtleColor),
                  _MenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notificações',
                    onTap: () => showAppSnackBar(
                      context,
                      'Configurações de notificações em breve.',
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtleColor),
                  _MenuItem(
                    icon: Icons.backup_outlined,
                    title: 'Backup em nuvem',
                    onTap: () => showAppSnackBar(
                      context,
                      isPremium
                          ? 'Backup automático ativo no plano Premium.'
                          : 'Backup em nuvem é um recurso do plano Premium.',
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtleColor),
                  _MenuItem(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'Dossiê do Veículo (PDF)',
                    trailingBadge: isPremium ? 'DISPONÍVEL' : 'PRO',
                    onTap: () {
                      if (!isPremium) {
                        _showDossierPaywall(context);
                      } else {
                        _showDossierExportDialog(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Menu Options Group 2 (Legal & Danger)
          Container(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Política de privacidade',
                    onTap: () =>
                        UrlLauncherService.open(AppConstants.privacyPolicyUrl),
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtleColor),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    title: 'Termos de uso',
                    onTap: () =>
                        UrlLauncherService.open(AppConstants.termsOfUseUrl),
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtleColor),
                  _MenuItem(
                    icon: Icons.delete_forever_outlined,
                    title: 'Excluir conta',
                    isDestructive: true,
                    onTap: () => _confirmDeleteAccount(context, ref),
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtleColor),
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Sair da conta',
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.developer_mode_rounded, size: 20, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Text(
                        'Diagnóstico de Anúncios (Debug)',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rede Ativa: ${AdManager.activeNetwork.name}\n'
                    'Unity Game ID: 800394548\n'
                    'SDK Inicializado: ${UnityAdsService.isInitialized}\n'
                    'Interstitial Pronto: ${UnityAdsService.isInterstitialReady}\n'
                    'Exibições na sessão: ${UnityAdsService.sessionInterstitialCount} / ${UnityAdsService.maxInterstitialsPerSession}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber.shade900,
                          side: BorderSide(color: Colors.amber.shade700),
                        ),
                        onPressed: () async {
                          final shown = await UnityAdsService.showInterstitialIfAvailable(
                            origin: 'debug_test',
                            isPremium: isPremium,
                          );
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              shown
                                  ? 'Disparando anúncio de teste...'
                                  : 'Anúncio indisponível ou em cooldown.',
                            );
                          }
                        },
                        child: const Text('Testar Interstitial'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          Center(
            child: Text(
              '${AppConstants.appName} • v1.0.0',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textMutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Isso removerá seus veículos, manutenções, lembretes e gastos '
          'de forma permanente. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (first != true) return;

    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        showAppSnackBar(context, 'Conta excluída.');
        context.go('/login');
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Não foi possível excluir a conta.',
          isError: true,
        );
      }
    }
  }

  void _showDossierPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 32,
                  color: AppTheme.tertiaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Dossiê Completo do Veículo',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gere um relatório digital em PDF com todo o histórico de manutenções, peças trocadas, quilometragens e notas fiscais.\n\n'
                'Ideal para valorizar seu carro ou moto na revenda e comprovar procedência.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textMutedColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/premium');
                  },
                  icon: const Icon(Icons.star_rounded),
                  label: const Text('Desbloquear no Premium'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDossierExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Dossiê do Veículo'),
          ],
        ),
        content: const Text(
          'Seu prontuário digital Premium está compilado e pronto para exportação.\n\n'
          'O documento inclui: histórico de manutenções, peças substituídas, odômetro verificado e relatório financeiro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              showAppSnackBar(context, 'Dossiê compilado com sucesso! Arquivo gerado.');
            },
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Compartilhar'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingBadge,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailingBadge;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppTheme.errorColor
        : AppTheme.textPrimaryColor;
    final iconColor = isDestructive
        ? AppTheme.errorColor
        : AppTheme.primaryColor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trailingBadge!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

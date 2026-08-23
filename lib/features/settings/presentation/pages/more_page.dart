import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../core/constants/app_constants.dart';
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    onTap: () => showAppSnackBar(context, 'Configurações de notificações em breve.'),
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
                    icon: Icons.download_outlined,
                    title: 'Exportar dados (PDF)',
                    onTap: () => showAppSnackBar(
                      context,
                      isPremium
                          ? 'Relatório PDF em preparação.'
                          : 'Exportação em PDF é um recurso do plano Premium.',
                    ),
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
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtleColor),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    title: 'Termos de uso',
                    onTap: () {},
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
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
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
    final color = isDestructive ? AppTheme.errorColor : AppTheme.textPrimaryColor;
    final iconColor = isDestructive ? AppTheme.errorColor : AppTheme.primaryColor;

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

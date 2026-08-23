import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

/// Top bar padronizada seguindo o design system do Auto em Dia.
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.showProfile = true,
    this.actions,
    this.leading,
  });

  final String title;
  final bool showProfile;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStreamProvider).value;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: leading!,
                )
              else ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              if (actions != null) ...?actions,
              if (showProfile)
                InkWell(
                  onTap: () => context.go('/more'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        auth != null && auth.name.isNotEmpty
                            ? auth.name.substring(0, 1).toUpperCase()
                            : 'M',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

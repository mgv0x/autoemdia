import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/services/firebase_bootstrap.dart';

/// Splash screen: exibe marca/slogan e decide a rota inicial.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    // O router decide com base no estado de auth; se o Firebase não
    // inicializou, o usuário verá o fluxo normalmente (as telas lidam
    // individualmente com a ausência via estados de loading/erro).
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.directions_car_rounded,
                  size: 56,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName.toUpperCase(),
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  AppConstants.appSlogan,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Inicializa o Firebase em background para aparecer o quanto antes.
              FutureBuilder(
                future: FirebaseBootstrap.initialize(),
                builder: (_, snapshot) {
                  if (snapshot.hasError) {
                    return const Icon(Icons.error_outline, color: Colors.red);
                  }
                  return const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

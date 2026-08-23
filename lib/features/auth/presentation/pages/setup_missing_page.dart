import 'package:flutter/material.dart';

/// Tela exibida quando o Firebase não foi configurado.
/// Evita crash e orienta o desenvolvedor.
class SetupMissingPage extends StatelessWidget {
  const SetupMissingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.settings_suggest_outlined,
                  size: 72,
                  color: scheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Configuração necessária',
                  textAlign: TextAlign.center,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Configure o Firebase.\n\n'
                  '1) Crie um projeto no Firebase Console.\n'
                  '2) Adicione o app Android (package com.autoemdia.app).\n'
                  '3) Rode: flutterfire configure\n'
                  '4) Baixe o google-services.json para android/app/.\n\n'
                  'Depois rode novamente.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

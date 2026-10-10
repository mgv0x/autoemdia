import 'package:url_launcher/url_launcher.dart';

/// Serviço para abrir URLs externas (política de privacidade, termos etc.).
abstract final class UrlLauncherService {
  static Future<void> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Falha ao abrir: ignore silenciosamente (não deve quebrar o app).
    }
  }
}

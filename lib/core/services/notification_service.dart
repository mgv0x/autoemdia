import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';

/// Serviço de notificações locais (flutter_local_notifications).
/// MVP usa notificações locais para os lembretes.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
      } catch (_) {
        // Se o TZ não existir, segue com o default UTC.
      }

      const androidSettings = AndroidInitializationSettings('ic_notification');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings: initSettings);

      // Android 13+: solicita permissão em runtime de forma segura
      try {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      } catch (e) {
        debugPrint('Permissão de notificações ignorada no start: $e');
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Erro ao inicializar NotificationService: $e');
    }
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification',
    ),
  );

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await init();
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (e) {
      debugPrint('Erro ao exibir notificação imediata: $e');
    }
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    try {
      await init();
      final tzDate = tz.TZDateTime.from(date, tz.local);
      if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDate,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        // Fallback para agendamento inexato se o dispositivo (ex: Android 14+) bloquear alarmes exatos
        debugPrint('Fallback de agendamento de notificação para inexact: $e');
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDate,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexact,
        );
      }
    } catch (e) {
      debugPrint('Erro ao agendar notificação: $e');
    }
  }

  /// Agenda um lembrete por data, com avisos em 30d/7d/no dia.
  Future<void> scheduleReminderByDate({
    required int baseId,
    required String title,
    required DateTime dueDate,
  }) async {
    try {
      final now = DateTime.now();
      for (final daysBefore in AppConstants.reminderNotifyDaysBefore) {
        final notifyAt = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          9,
        ).subtract(Duration(days: daysBefore));
        if (notifyAt.isBefore(now)) continue;

        final (t, b) = _reminderCopy(title, daysBefore);
        await schedule(
          id: baseId + daysBefore,
          title: t,
          body: b,
          date: notifyAt,
        );
      }
    } catch (e) {
      debugPrint('Erro ao agendar lembrete por data: $e');
    }
  }

  (String, String) _reminderCopy(String title, int daysBefore) {
    return switch (daysBefore) {
      30 => ('Sua revisão está chegando 🚗', '"$title" vence em 30 dias.'),
      7 => ('Revisão em 7 dias 🔧', 'Falta 1 semana para "$title".'),
      _ => ('Sua revisão é hoje ⚠️', '"$title" está prevista para hoje.'),
    };
  }

  /// Lembrete periódico (mensal) para o usuário registrar a quilometragem
  /// atual do veículo — mantém cálculos de custo/km e metas precisos.
  static const mileageReminderId = 990001;

  Future<void> scheduleMileageReminder() async {
    try {
      await init();
      // Cancela agendamentos anteriores para não duplicar.
      await cancel(mileageReminderId);

      final now = DateTime.now();
      // Próximo dia 1º às 10h (horário local).
      var next = DateTime(now.year, now.month + 1, 1, 10);

      await _plugin.zonedSchedule(
        id: mileageReminderId,
        title: 'Registrando a quilometragem 📝',
        body:
            'Atualize o km do seu veículo para mantermos os lembretes em dia.',
        scheduledDate: tz.TZDateTime.from(next, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        // Repete mensalmente enquanto o app for usado.
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      debugPrint('Erro ao agendar lembrete de quilometragem: $e');
    }
  }

  /// Cancela o lembrete periódico de quilometragem.
  Future<void> cancelMileageReminder() async {
    try {
      await cancel(mileageReminderId);
    } catch (_) {
      // Silencioso: cancelamento não crítico.
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Gera um id numérico estável para um lembrete (a partir do uuid).
  static int notificationIdFromUuid(String uuid) =>
      uuid.hashCode.abs() % 1000000;
}

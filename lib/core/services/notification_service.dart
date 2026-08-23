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
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    } catch (_) {
      // Se o TZ não existir, segue com o default UTC.
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);

    // Android 13+: solicita permissão em runtime.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    await init();
    final tzDate = tz.TZDateTime.from(date, tz.local);
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Agenda um lembrete por data, com avisos em 30d/7d/no dia.
  Future<void> scheduleReminderByDate({
    required int baseId,
    required String title,
    required DateTime dueDate,
  }) async {
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
  }

  (String, String) _reminderCopy(String title, int daysBefore) {
    return switch (daysBefore) {
      30 => ('Sua revisão está chegando 🚗', '"$title" vence em 30 dias.'),
      7 => ('Revisão em 7 dias 🔧', 'Falta 1 semana para "$title".'),
      _ => ('Sua revisão é hoje ⚠️', '"$title" está prevista para hoje.'),
    };
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Gera um id numérico estável para um lembrete (a partir do uuid).
  static int notificationIdFromUuid(String uuid) =>
      uuid.hashCode.abs() % 1000000;
}

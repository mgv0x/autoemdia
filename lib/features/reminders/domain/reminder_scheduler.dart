import '../../../../core/services/notification_service.dart';
import '../domain/reminder_entity.dart';

/// Agenda/cancela notificações locais para um lembrete.
/// MVP usa notificações locais (mais simples que push).
Future<void> scheduleReminderNotifications(ReminderEntity reminder) async {
  if (!reminder.notificationEnabled || reminder.completed) return;
  final dueDate = reminder.dueDate;
  if (dueDate == null) return; // notificação por km é avaliada em runtime

  final baseId = NotificationService.notificationIdFromUuid(reminder.id);
  await NotificationService.instance.scheduleReminderByDate(
    baseId: baseId,
    title: reminder.title,
    dueDate: dueDate,
  );
}

Future<void> cancelReminderNotifications(String reminderId) async {
  final baseId = NotificationService.notificationIdFromUuid(reminderId);
  // Cancela os possíveis avisos (30d/7d/no dia).
  for (final d in const [30, 7, 0]) {
    await NotificationService.instance.cancel(baseId + d);
  }
}

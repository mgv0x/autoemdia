import 'package:intl/intl.dart';

/// Formatadores centralizados (locale pt-BR).
abstract final class Formatters {
  static final _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  static final _date = DateFormat('dd/MM/yyyy');
  static final _dateTime = DateFormat("dd/MM/yyyy 'às' HH:mm");
  static final _km = NumberFormat('#,##0', 'pt_BR');

  static String currency(num value) => _currency.format(value);
  static String date(DateTime d) => _date.format(d.toLocal());
  static String dateTime(DateTime d) => _dateTime.format(d.toLocal());
  static String mileage(num km) => '${_km.format(km)} km';

  static DateTime? tryParseDate(String? iso) =>
      iso == null ? null : DateTime.tryParse(iso);
}

/// Extensões utilitárias para datas.
extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

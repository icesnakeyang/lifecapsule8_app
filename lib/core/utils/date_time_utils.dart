import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String dateTime(DateTime dateTime, {String? locale}) {
    final local = dateTime.toLocal();
    return DateFormat.yMMMd(locale).add_Hm().format(local);
  }

  static String date(DateTime dateTime, {String? locale}) {
    final local = dateTime.toLocal();
    return DateFormat.yMMMd(locale).format(local);
  }

  static String time(DateTime dateTime, {String? locale}) {
    final local = dateTime.toLocal();
    return DateFormat.Hm(locale).format(local);
  }

  /// yyyy-MM-dd HH:mm (常用于列表)
  static String ymdHm(DateTime dateTime) {
    final local = dateTime.toLocal();

    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');

    return '$y-$m-$d $hh:$mm';
  }
}

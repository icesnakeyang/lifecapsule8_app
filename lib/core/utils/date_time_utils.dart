import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(DateTime dateTime, String locale) {
    final local = dateTime.toLocal();
    return DateFormat.yMMMd(locale).add_Hm().format(local);
  }

  static String formatDate(DateTime dateTime, String locale) {
    final local = dateTime.toLocal();
    return DateFormat.yMMMd(locale).format(local);
  }

  static String formatTime(DateTime dateTime, String locale) {
    final local = dateTime.toLocal();
    return DateFormat.Hm(locale).format(local);
  }
}

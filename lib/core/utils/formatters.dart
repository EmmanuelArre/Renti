/// Formatos de dinero y fecha compartidos por las pantallas.

String formatMoney(int v) {
  final s = v.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}\$$buf';
}

const _months = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

DateTime addMonths(DateTime d, int months) =>
    DateTime(d.year, d.month + months, d.day);

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

String formatDateTime(DateTime d) =>
    '${formatDate(d)} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

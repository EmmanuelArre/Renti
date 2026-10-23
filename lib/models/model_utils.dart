import 'dart:convert';

/// Utilidades de conversión usadas por los modelos (Firestore y SQLite
/// devuelven tipos ligeramente distintos).

String asString(Object? v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

int asInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

double? asDoubleOrNull(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool asBool(Object? v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return fallback;
}

DateTime asDate(Object? v) {
  if (v is DateTime) return v.toLocal();
  final d = DateTime.tryParse(v?.toString() ?? '');
  return (d ?? DateTime.now()).toLocal();
}

String iso(DateTime d) => d.toUtc().toIso8601String();

/// Acepta una lista nativa (Firestore) o un JSON (SQLite).
List<String> asStringList(Object? v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is String && v.isNotEmpty) {
    try {
      final d = jsonDecode(v);
      if (d is List) return d.map((e) => e.toString()).toList();
    } catch (_) {}
  }
  return const [];
}

String inicialesDe(String nombre) => nombre
    .split(' ')
    .where((s) => s.isNotEmpty)
    .take(2)
    .map((s) => s[0].toUpperCase())
    .join();

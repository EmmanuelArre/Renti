import 'package:renti/models/model_utils.dart';

/// Aviso para una persona usuaria. Documento `notificaciones/{id}`.
class AppNotification {
  final String id;
  final String userId;
  final String originId; // quién la generó (las reglas lo exigen)
  final String type; // solicitud | arrendamiento | moderacion | reporte
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.originId,
    required this.type,
    required this.title,
    required this.message,
    this.read = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        userId: userId,
        originId: originId,
        type: type,
        title: title,
        message: message,
        read: read ?? this.read,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'usuarioId': userId,
        'origenId': originId,
        'tipo': type,
        'titulo': title,
        'mensaje': message,
        'leida': read,
        'creadoEn': iso(createdAt),
      };

  Map<String, Object?> toRow() => {
        'id': id,
        'usuario_id': userId,
        'origen_id': originId,
        'tipo': type,
        'titulo': title,
        'mensaje': message,
        'leida': read ? 1 : 0,
        'creado_en': iso(createdAt),
      };

  factory AppNotification.fromMap(Map<String, Object?> m, {String? id}) =>
      AppNotification(
        id: id ?? asString(m['id']),
        userId: asString(m['usuarioId'] ?? m['usuario_id']),
        originId: asString(m['origenId'] ?? m['origen_id']),
        type: asString(m['tipo']),
        title: asString(m['titulo']),
        message: asString(m['mensaje']),
        read: asBool(m['leida']),
        createdAt: asDate(m['creadoEn'] ?? m['creado_en']),
      );
}

import 'package:renti/models/model_utils.dart';

/// Resumen de una conversación (`chats/{chatId}`).
class ChatPreview {
  final String id;
  final String otherId;
  final String name;
  final String initials;
  final String lastMessage;
  final DateTime? lastDate;
  final bool unread;

  const ChatPreview({
    required this.id,
    required this.otherId,
    required this.name,
    required this.initials,
    required this.lastMessage,
    this.lastDate,
    this.unread = false,
  });

  String get time {
    final d = lastDate;
    if (d == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    if (diff == 1) return 'Ayer';
    return '${d.day}/${d.month}';
  }

  factory ChatPreview.fromMap(
    String id,
    Map<String, Object?> m,
    String myUid,
  ) {
    final parts = (m['participantes'] as List? ?? const []).cast<Object?>();
    final other = parts.map((e) => e.toString()).firstWhere(
          (p) => p != myUid,
          orElse: () => '',
        );
    final names = (m['nombres'] as Map?) ?? const {};
    final name = asString(names[other], 'Usuario');
    return ChatPreview(
      id: id,
      otherId: other,
      name: name,
      initials: inicialesDe(name),
      lastMessage: asString(m['ultimoMensaje']),
      lastDate: m['ultimaFecha'] == null ? null : asDate(m['ultimaFecha']),
      unread: asString(m['ultimoRemitente']) != myUid &&
          asString(m['ultimoMensaje']).isNotEmpty &&
          asString(m['leidoPor']) != myUid,
    );
  }
}

class ChatMessage {
  final String text;
  final bool mine;
  final DateTime? date;
  const ChatMessage(this.text, {this.mine = false, this.date});
}

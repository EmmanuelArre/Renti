import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/services/data_source.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/models/app_user.dart';
import 'package:renti/models/chat.dart';
import 'package:renti/models/model_utils.dart';

/// Mensajería entre estudiante y arrendador.
/// `chats/{uidA_uidB}` + subcolección `mensajes`. Se lee en tiempo real.
class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _chats =>
      _fs.collection(Coleccion.chats);

  /// Id estable para dos personas (sin importar quién escribe primero).
  static String idDe(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  Stream<List<ChatPreview>> conversaciones(String miUid) {
    return _chats
        .where('participantes', arrayContains: miUid)
        .snapshots()
        .map((snap) {
      final lista = snap.docs
          .map((d) => ChatPreview.fromMap(d.id, d.data(), miUid))
          .toList();
      lista.sort((a, b) => (b.lastDate ?? DateTime(2000))
          .compareTo(a.lastDate ?? DateTime(2000)));
      return lista;
    });
  }

  Stream<List<ChatMessage>> mensajes(String chatId, String miUid) {
    return _chats
        .doc(chatId)
        .collection(Coleccion.mensajes)
        .orderBy('creadoEn')
        .limitToLast(200)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data();
              return ChatMessage(
                asString(m['texto']),
                mine: asString(m['de']) == miUid,
                date: asDate(m['creadoEn']),
              );
            }).toList());
  }

  Future<void> enviar({
    required AppUser? yo,
    required String otroUid,
    required String otroNombre,
    required String texto,
  }) async {
    if (yo == null) throw const RentiException('Inicia sesión para chatear.');
    if (!yo.activo) throw const RentiException('Tu cuenta está suspendida.');
    if (otroUid.isEmpty || otroUid == yo.uid) {
      throw const RentiException('Conversación no válida.');
    }
    final t = texto.trim();
    if (t.isEmpty) throw const RentiException('Escribe un mensaje.');
    if (t.length > 1000) {
      throw const RentiException('El mensaje no puede pasar de 1000 caracteres.');
    }
    final id = idDe(yo.uid, otroUid);
    final ahora = ahoraIso();
    final ref = _chats.doc(id);
    await ref.set({
      'participantes': [yo.uid, otroUid]..sort(),
      'nombres': {yo.uid: yo.nombre, otroUid: otroNombre},
      'ultimoMensaje': t,
      'ultimaFecha': ahora,
      'ultimoRemitente': yo.uid,
      'leidoPor': yo.uid,
    }, SetOptions(merge: true));
    await ref.collection(Coleccion.mensajes).add({
      'de': yo.uid,
      'texto': t,
      'creadoEn': ahora,
    });
  }

  Future<void> marcarLeido(String chatId, String miUid) async {
    try {
      await _chats.doc(chatId).update({'leidoPor': miUid});
    } catch (_) {
      // El chat aún no existe (no se ha enviado ningún mensaje).
    }
  }
}

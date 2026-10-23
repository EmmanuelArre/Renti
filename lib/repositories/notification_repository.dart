import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/database/app_database.dart';
import 'package:renti/core/services/data_source.dart';
import 'package:renti/models/app_notification.dart';

/// Notificaciones: Firestore (`notificaciones`) + caché SQLite.
class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository instance = NotificationRepository._();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection(Coleccion.notificaciones);

  /// Crea un aviso para otra persona. Nunca lanza: un aviso fallido no debe
  /// romper la operación principal (aceptar una solicitud, por ejemplo).
  Future<void> avisar({
    required String paraUid,
    required String deUid,
    required String tipo,
    required String titulo,
    required String mensaje,
  }) async {
    try {
      final ref = _col.doc();
      await ref.set(AppNotification(
        id: ref.id,
        userId: paraUid,
        originId: deUid,
        type: tipo,
        title: titulo,
        message: mensaje,
      ).toMap());
    } catch (_) {
      // Se ignora a propósito (ver comentario del método).
    }
  }

  Future<Resultado<List<AppNotification>>> cargar(String uid) {
    return remotoOLocal<List<AppNotification>>(() async {
      final snap = await _col.where('usuarioId', isEqualTo: uid).limit(100).get();
      final lista = snap.docs
          .map((d) => AppNotification.fromMap(d.data(), id: d.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await cacheSegura(() async {
        final db = await AppDatabase.instance.database;
        await db.transaction((txn) async {
          await txn.delete('notificaciones',
              where: 'usuario_id = ?', whereArgs: [uid]);
          for (final n in lista) {
            await AppDatabase.upsert(txn, 'notificaciones', n.toRow());
          }
        });
      });
      return lista;
    }, () async {
      final db = await AppDatabase.instance.database;
      final filas = await db.query(
        'notificaciones',
        where: 'usuario_id = ?',
        whereArgs: [uid],
        orderBy: 'creado_en DESC',
      );
      return filas.map(AppNotification.fromMap).toList();
    });
  }

  Future<void> marcarLeidas(List<AppNotification> pendientes) async {
    if (pendientes.isEmpty) return;
    final batch = _fs.batch();
    for (final n in pendientes) {
      batch.update(_col.doc(n.id), {'leida': true});
    }
    await batch.commit();
    await cacheSegura(() async {
      final db = await AppDatabase.instance.database;
      await db.transaction((txn) async {
        for (final n in pendientes) {
          await txn.update('notificaciones', {'leida': 1},
              where: 'id = ?', whereArgs: [n.id]);
        }
      });
    });
  }
}

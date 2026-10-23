import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/database/app_database.dart';
import 'package:renti/core/services/data_source.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/repositories/property_repository.dart';

/// Favoritos de un estudiante: `usuarios/{uid}/favoritos/{propiedadId}` en
/// Firestore y tabla `favoritos` en SQLite.
class FavoriteRepository {
  FavoriteRepository._();
  static final FavoriteRepository instance = FavoriteRepository._();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _col(String uid) => _fs
      .collection(Coleccion.usuarios)
      .doc(uid)
      .collection(Coleccion.favoritos);

  /// Devuelve las propiedades favoritas. [conocidas] evita pedir de nuevo las
  /// que ya se descargaron en la lista pública.
  Future<Resultado<List<Listing>>> cargar(
    String uid,
    List<Listing> conocidas,
  ) {
    return remotoOLocal<List<Listing>>(() async {
      final snap = await _col(uid).get();
      final ids = snap.docs.map((d) => d.id).toList();
      final porId = {for (final l in conocidas) l.id: l};
      final lista = <Listing>[];
      for (final id in ids) {
        var l = porId[id];
        l ??= await PropertyRepository.instance.obtener(id);
        // Si la propiedad ya no existe o dejó de ser pública, se omite.
        if (l != null && l.isPublic) lista.add(l);
      }
      await cacheSegura(() async {
        for (final l in lista) {
          await PropertyRepository.instance.guardarEnCache(l);
        }
        final db = await AppDatabase.instance.database;
        await db.transaction((txn) async {
          await txn.delete('favoritos',
              where: 'usuario_id = ?', whereArgs: [uid]);
          for (final l in lista) {
            await txn.insert('favoritos', {
              'usuario_id': uid,
              'propiedad_id': l.id,
              'creado_en': ahoraIso(),
            });
          }
        });
      });
      return lista;
    }, () async {
      final db = await AppDatabase.instance.database;
      final filas = await db.rawQuery(
        'SELECT p.* FROM propiedades p '
        'JOIN favoritos f ON f.propiedad_id = p.id '
        'WHERE f.usuario_id = ? ORDER BY f.creado_en DESC',
        [uid],
      );
      return filas.map(Listing.fromMap).toList();
    });
  }

  Future<void> agregar(String uid, Listing l) async {
    await _col(uid).doc(l.id).set({
      'propiedadId': l.id,
      'creadoEn': ahoraIso(),
    });
    await cacheSegura(() async {
      await PropertyRepository.instance.guardarEnCache(l);
      final db = await AppDatabase.instance.database;
      final n = await db.update(
        'favoritos',
        {'creado_en': ahoraIso()},
        where: 'usuario_id = ? AND propiedad_id = ?',
        whereArgs: [uid, l.id],
      );
      if (n == 0) {
        await db.insert('favoritos', {
          'usuario_id': uid,
          'propiedad_id': l.id,
          'creado_en': ahoraIso(),
        });
      }
    });
  }

  Future<void> quitar(String uid, String propiedadId) async {
    await _col(uid).doc(propiedadId).delete();
    await cacheSegura(() async {
      final db = await AppDatabase.instance.database;
      await db.delete(
        'favoritos',
        where: 'usuario_id = ? AND propiedad_id = ?',
        whereArgs: [uid, propiedadId],
      );
    });
  }

  /// Ids de favoritos guardados localmente (para marcar corazones sin red).
  Future<Set<String>> idsLocales(String uid) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query('favoritos',
        columns: ['propiedad_id'], where: 'usuario_id = ?', whereArgs: [uid]);
    return filas.map((f) => f['propiedad_id'].toString()).toSet();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/database/app_database.dart';
import 'package:renti/core/services/data_source.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/models/app_user.dart';
import 'package:renti/models/model_utils.dart';

/// Perfiles de usuario: Firestore (`usuarios`) + caché SQLite (`usuarios`).
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection(Coleccion.usuarios);

  // ------------------------------------------------------------------ nube

  /// Un administrador existe solo si hay un documento `admins/{uid}`, que
  /// únicamente se puede crear desde la consola de Firebase.
  Future<bool> esAdministrador(String uid) async {
    final d = await _fs.collection(Coleccion.admins).doc(uid).get();
    return d.exists;
  }

  Future<AppUser?> obtener(String uid) async {
    final d = await _col.doc(uid).get();
    if (!d.exists) return null;
    return AppUser.fromMap(d.data()!, uid: d.id);
  }

  /// Crea el perfil. El rol solo puede ser arrendador o arrendatario; las
  /// reglas de Firestore lo vuelven a comprobar en el servidor.
  Future<void> crear(AppUser u) async {
    if (!Roles.esRegistrable(u.rol)) {
      throw const RentiException('Rol no permitido para el registro.');
    }
    await _col.doc(u.uid).set(u.toMap());
    await guardarLocal(u);
  }

  Future<AppUser> actualizarPerfil(
    AppUser actual, {
    required String nombre,
    required String telefono,
    required String universidad,
  }) async {
    final errores = [
      Validators.nombreCompleto(nombre),
      Validators.telefonoOpcional(telefono),
    ].whereType<String>();
    if (errores.isNotEmpty) throw RentiException(errores.first);

    final nuevo = actual.copyWith(
      nombre: Validators.normalizarEspacios(nombre),
      telefono: telefono.replaceAll(RegExp(r'[\s\-()]'), ''),
      universidad: universidad,
    );
    await _col.doc(actual.uid).update({
      'nombre': nuevo.nombre,
      'telefono': nuevo.telefono,
      'universidad': nuevo.universidad,
      'actualizadoEn': iso(nuevo.actualizadoEn),
    });
    await guardarLocal(nuevo);
    return nuevo;
  }

  /// Solo administrador: lista usuarios, opcionalmente por rol.
  Future<List<AppUser>> listar({String? rol}) async {
    Query<Map<String, dynamic>> q = _col;
    if (rol != null) q = q.where('rol', isEqualTo: rol);
    final snap = await q.limit(300).get();
    final lista =
        snap.docs.map((d) => AppUser.fromMap(d.data(), uid: d.id)).toList();
    lista.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    return lista;
  }

  /// Solo administrador: activa o suspende una cuenta.
  Future<void> cambiarEstado(String uid, String estado) async {
    if (estado != EstadoCuenta.activo && estado != EstadoCuenta.suspendido) {
      throw const RentiException('Estado de cuenta no válido.');
    }
    await _col.doc(uid).update({
      'estado': estado,
      'actualizadoEn': ahoraIso(),
    });
  }

  // ---------------------------------------------------------------- SQLite

  Future<void> guardarLocal(AppUser u) => cacheSegura(() async {
        final db = await AppDatabase.instance.database;
        await AppDatabase.upsert(db, 'usuarios', u.toRow(), clave: 'uid');
      });

  Future<AppUser?> obtenerLocal(String uid) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'usuarios',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    return filas.isEmpty ? null : AppUser.fromMap(filas.first);
  }

  Future<int> contarLocal() async {
    final db = await AppDatabase.instance.database;
    return Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM usuarios')) ??
        0;
  }
}

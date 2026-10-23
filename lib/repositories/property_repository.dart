import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/database/app_database.dart';
import 'package:renti/core/services/data_source.dart';
import 'package:renti/core/services/image_service.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/models/app_user.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/models/model_utils.dart';

/// Datos de formulario para crear o editar una propiedad.
class DatosPropiedad {
  final String titulo;
  final String tipo;
  final String direccion;
  final String referencia;
  final String precio; // texto tal como lo escribió la persona
  final String descripcion;
  final String habitaciones;
  final String banos;
  final List<String> servicios;

  const DatosPropiedad({
    required this.titulo,
    required this.tipo,
    required this.direccion,
    required this.referencia,
    required this.precio,
    required this.descripcion,
    required this.habitaciones,
    required this.banos,
    required this.servicios,
  });

  /// Primer mensaje de error de las reglas de negocio, o null si todo es válido.
  String? validar() => [
        Validators.tituloPropiedad(titulo),
        Validators.tipoPropiedad(tipo),
        Validators.direccion(direccion),
        Validators.ubicacion(referencia),
        Validators.precio(precio),
        Validators.descripcion(descripcion),
        Validators.enteroEnRango(habitaciones, 'Habitaciones', 0, 20),
        Validators.enteroEnRango(banos, 'Baños', 1, 20),
        Validators.serviciosSeleccionados(servicios),
      ].whereType<String>().firstOrNull;
}

/// Propiedades: Firestore (`propiedades` + subcolección `imagenes`) y caché
/// SQLite (`propiedades`, `imagenes_propiedad`).
class PropertyRepository {
  PropertyRepository._();
  static final PropertyRepository instance = PropertyRepository._();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection(Coleccion.propiedades);

  static List<Listing> _ordenar(List<Listing> l) {
    l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  static List<Listing> _desdeDocs(
          Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) =>
      _ordenar(docs.map((d) => Listing.fromMap(d.data(), id: d.id)).toList());

  // ------------------------------------------------------------- consultas

  /// Propiedades que ven los estudiantes: aprobadas y disponibles.
  Future<Resultado<List<Listing>>> publicas(String miUid) {
    return remotoOLocal<List<Listing>>(() async {
      final snap = await _col
          .where('moderacion', isEqualTo: Moderacion.aprobada)
          .where('estado', isEqualTo: ListingStatus.disponible.name)
          .limit(200)
          .get();
      final lista = _desdeDocs(snap.docs);
      await cacheSegura(() => _cachearPublicas(lista, miUid));
      return lista;
    }, () async {
      final db = await AppDatabase.instance.database;
      final filas = await db.query(
        'propiedades',
        where: "moderacion = 'aprobada' AND estado = 'disponible'",
      );
      return _ordenar(filas.map(Listing.fromMap).toList());
    });
  }

  /// Propiedades de un arrendador (cualquier estado de moderación).
  Future<Resultado<List<Listing>>> delPropietario(String uid) {
    return remotoOLocal<List<Listing>>(() async {
      final snap = await _col.where('propietarioId', isEqualTo: uid).get();
      final lista = _desdeDocs(snap.docs);
      await cacheSegura(() async {
        final db = await AppDatabase.instance.database;
        await db.transaction((txn) async {
          for (final l in lista) {
            await AppDatabase.upsert(txn, 'propiedades', l.toRow());
          }
          final ids = lista.map((l) => l.id).toList();
          await txn.delete(
            'propiedades',
            where:
                'propietario_id = ? AND id NOT IN (${List.filled(ids.length, '?').join(',')})',
            whereArgs: [uid, ...ids],
          );
        });
      });
      return lista;
    }, () async {
      final db = await AppDatabase.instance.database;
      final filas = await db.query(
        'propiedades',
        where: 'propietario_id = ?',
        whereArgs: [uid],
      );
      return _ordenar(filas.map(Listing.fromMap).toList());
    });
  }

  Future<Listing?> obtener(String id) async {
    final d = await _col.doc(id).get();
    if (!d.exists) return null;
    return Listing.fromMap(d.data()!, id: d.id);
  }

  /// Fotos completas (base64) de una propiedad, en orden.
  Future<List<String>> imagenes(String id) async {
    try {
      final snap = await _col
          .doc(id)
          .collection(Coleccion.imagenes)
          .orderBy('orden')
          .get()
          .timeout(const Duration(seconds: 10));
      final fotos = snap.docs.map((d) => asString(d.data()['datos'])).toList();
      await cacheSegura(() async {
        final db = await AppDatabase.instance.database;
        final existe = Sqflite.firstIntValue(await db.rawQuery(
                'SELECT COUNT(*) FROM propiedades WHERE id = ?', [id])) ??
            0;
        if (existe == 0) return; // sin padre no hay FK que cumplir
        await db.transaction((txn) async {
          await txn.delete('imagenes_propiedad',
              where: 'propiedad_id = ?', whereArgs: [id]);
          for (var i = 0; i < fotos.length; i++) {
            await txn.insert('imagenes_propiedad', {
              'id': '${id}_$i',
              'propiedad_id': id,
              'orden': i,
              'datos': fotos[i],
              'creado_en': ahoraIso(),
            });
          }
        });
      });
      return fotos;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') rethrow;
      return _imagenesLocal(id);
    } catch (_) {
      return _imagenesLocal(id);
    }
  }

  Future<List<String>> _imagenesLocal(String id) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'imagenes_propiedad',
      columns: ['datos'],
      where: 'propiedad_id = ?',
      whereArgs: [id],
      orderBy: 'orden',
    );
    return filas.map((f) => asString(f['datos'])).toList();
  }

  /// Solo administrador: todas las publicaciones.
  Future<List<Listing>> todas() async {
    final snap = await _col.limit(300).get();
    return _desdeDocs(snap.docs);
  }

  // ----------------------------------------------------------- escritura

  Future<Listing> crear({
    required AppUser propietario,
    required DatosPropiedad datos,
    required List<FotoPropiedad> fotos,
  }) async {
    if (!propietario.esArrendador || !propietario.activo) {
      throw const RentiException(
          'Solo un arrendador con cuenta activa puede publicar propiedades.');
    }
    final error = datos.validar() ?? Validators.cantidadFotos(fotos.length);
    if (error != null) throw RentiException(error);

    final ref = _col.doc();
    final cover = ImageService.instance.miniatura(fotos.first.datos);
    final ahora = DateTime.now();
    final listing = Listing(
      id: ref.id,
      ownerId: propietario.uid,
      landlord: propietario.nombre,
      title: Validators.normalizarEspacios(datos.titulo),
      type: datos.tipo,
      address: Validators.normalizarEspacios(datos.direccion),
      distance: Validators.normalizarEspacios(datos.referencia),
      price: Validators.parsearEntero(datos.precio)!,
      description: Validators.normalizarEspacios(datos.descripcion),
      bedrooms: int.parse(datos.habitaciones.trim()),
      bathrooms: int.parse(datos.banos.trim()),
      shared: datos.tipo == 'Compartido',
      services: datos.servicios,
      status: ListingStatus.disponible,
      moderation: Moderacion.pendiente, // el administrador debe aprobarla
      cover: cover,
      createdAt: ahora,
      updatedAt: ahora,
    );

    final batch = _fs.batch();
    batch.set(ref, listing.toMap());
    for (var i = 0; i < fotos.length; i++) {
      batch.set(ref.collection(Coleccion.imagenes).doc('f$i'), {
        'orden': i,
        'datos': fotos[i].datos,
        'creadoEn': iso(ahora),
      });
    }
    await batch.commit();
    await cacheSegura(() => _guardarLocal(listing, fotos.map((f) => f.datos).toList()));
    return listing;
  }

  /// Edita el contenido. Si [fotos] no es null reemplaza todas las fotos.
  /// Cualquier edición vuelve a poner la publicación "en revisión".
  Future<Listing> actualizar({
    required Listing original,
    required DatosPropiedad datos,
    List<FotoPropiedad>? fotos,
  }) async {
    if (original.moderation == Moderacion.desactivada) {
      throw const RentiException(
          'El administrador desactivó esta publicación; no se puede editar.');
    }
    final error = datos.validar() ??
        (fotos == null ? null : Validators.cantidadFotos(fotos.length));
    if (error != null) throw RentiException(error);

    final cover = fotos == null
        ? original.cover
        : ImageService.instance.miniatura(fotos.first.datos);
    final nuevo = original.copyWith(
      title: Validators.normalizarEspacios(datos.titulo),
      type: datos.tipo,
      address: Validators.normalizarEspacios(datos.direccion),
      distance: Validators.normalizarEspacios(datos.referencia),
      price: Validators.parsearEntero(datos.precio)!,
      description: Validators.normalizarEspacios(datos.descripcion),
      bedrooms: int.parse(datos.habitaciones.trim()),
      bathrooms: int.parse(datos.banos.trim()),
      shared: datos.tipo == 'Compartido',
      services: datos.servicios,
      moderation: Moderacion.pendiente,
      cover: cover,
    );

    final ref = _col.doc(original.id);
    final batch = _fs.batch();
    final cambios = nuevo.toMap()
      ..remove('propietarioId')
      ..remove('propietarioNombre')
      ..remove('creadoEn');
    batch.update(ref, cambios);
    if (fotos != null) {
      final viejas = await ref.collection(Coleccion.imagenes).get();
      for (final d in viejas.docs) {
        batch.delete(d.reference);
      }
      for (var i = 0; i < fotos.length; i++) {
        batch.set(ref.collection(Coleccion.imagenes).doc('f$i'), {
          'orden': i,
          'datos': fotos[i].datos,
          'creadoEn': ahoraIso(),
        });
      }
    }
    await batch.commit();
    await cacheSegura(() => _guardarLocal(nuevo, fotos?.map((f) => f.datos).toList()));
    return nuevo;
  }

  /// El arrendador marca la propiedad como disponible o rentada.
  Future<Listing> cambiarDisponibilidad(
      Listing l, ListingStatus status) async {
    final nuevo = l.copyWith(status: status);
    await _col.doc(l.id).update({
      'estado': status.name,
      'actualizadoEn': iso(nuevo.updatedAt),
    });
    await cacheSegura(() => _guardarLocal(nuevo, null));
    return nuevo;
  }

  /// Elimina la propiedad y sus fotos. No se permite si tiene una renta
  /// activa; las solicitudes pendientes se rechazan.
  Future<void> eliminar(Listing l) async {
    final activos = await _fs
        .collection(Coleccion.arrendamientos)
        .where('arrendadorId', isEqualTo: l.ownerId)
        .where('propiedadId', isEqualTo: l.id)
        .where('estado', isEqualTo: EstadoArrendamiento.activa)
        .limit(1)
        .get();
    if (activos.docs.isNotEmpty) {
      throw const RentiException(
          'No puedes eliminar una propiedad con un arrendamiento activo. '
          'Finalízalo primero.');
    }
    final pendientes = await _fs
        .collection(Coleccion.solicitudes)
        .where('arrendadorId', isEqualTo: l.ownerId)
        .where('propiedadId', isEqualTo: l.id)
        .where('estado', isEqualTo: EstadoSolicitud.pendiente)
        .get();
    final ref = _col.doc(l.id);
    final fotos = await ref.collection(Coleccion.imagenes).get();
    final batch = _fs.batch();
    for (final d in fotos.docs) {
      batch.delete(d.reference);
    }
    for (final d in pendientes.docs) {
      batch.update(d.reference, {
        'estado': EstadoSolicitud.rechazada,
        'actualizadoEn': ahoraIso(),
      });
    }
    batch.delete(ref);
    await batch.commit();
    await cacheSegura(() async {
      final db = await AppDatabase.instance.database;
      await db.delete('propiedades', where: 'id = ?', whereArgs: [l.id]);
    });
  }

  /// Solo administrador: aprobar, rechazar o desactivar.
  Future<void> moderar(String id, String moderacion, {String motivo = ''}) async {
    if (!Moderacion.todos.contains(moderacion)) {
      throw const RentiException('Estado de moderación no válido.');
    }
    await _col.doc(id).update({
      'moderacion': moderacion,
      'motivoModeracion': motivo,
      'actualizadoEn': ahoraIso(),
    });
  }

  // --------------------------------------------------------------- SQLite

  Future<void> _guardarLocal(Listing l, List<String>? fotos) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await AppDatabase.upsert(txn, 'propiedades', l.toRow());
      if (fotos != null) {
        await txn.delete('imagenes_propiedad',
            where: 'propiedad_id = ?', whereArgs: [l.id]);
        for (var i = 0; i < fotos.length; i++) {
          await txn.insert('imagenes_propiedad', {
            'id': '${l.id}_$i',
            'propiedad_id': l.id,
            'orden': i,
            'datos': fotos[i],
            'creado_en': ahoraIso(),
          });
        }
      }
    });
  }

  /// Guarda la lista pública y elimina de la caché las que ya no lo son
  /// (sin tocar las propias ni las marcadas como favoritas).
  Future<void> _cachearPublicas(List<Listing> lista, String miUid) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      for (final l in lista) {
        await AppDatabase.upsert(txn, 'propiedades', l.toRow());
      }
      final ids = lista.map((l) => l.id).toList();
      await txn.delete(
        'propiedades',
        where: "moderacion = 'aprobada' AND estado = 'disponible' "
            'AND propietario_id <> ? '
            'AND id NOT IN (${List.filled(ids.length, '?').join(',')}) '
            'AND id NOT IN (SELECT propiedad_id FROM favoritos)',
        whereArgs: [miUid, ...ids],
      );
    });
  }

  Future<Listing?> obtenerLocal(String id) async {
    final db = await AppDatabase.instance.database;
    final filas =
        await db.query('propiedades', where: 'id = ?', whereArgs: [id], limit: 1);
    return filas.isEmpty ? null : Listing.fromMap(filas.first);
  }

  /// Usado por pruebas y por el repositorio de favoritos.
  Future<void> guardarEnCache(Listing l) => cacheSegura(() => _guardarLocal(l, null));
}

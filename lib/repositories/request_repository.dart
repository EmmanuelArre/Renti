import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/database/app_database.dart';
import 'package:renti/core/services/data_source.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/models/app_user.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/models/rental.dart';

/// Solicitudes de arrendamiento y arrendamientos resultantes.
/// Firestore: `solicitudes`, `arrendamientos`. SQLite: tablas homónimas.
class RequestRepository {
  RequestRepository._();
  static final RequestRepository instance = RequestRepository._();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _sol =>
      _fs.collection(Coleccion.solicitudes);
  CollectionReference<Map<String, dynamic>> get _arr =>
      _fs.collection(Coleccion.arrendamientos);

  // ------------------------------------------------------------- enviar

  /// Valida las reglas de negocio y crea (o reabre) la solicitud.
  ///
  /// Reglas: sesión iniciada, rol arrendatario con cuenta activa, propiedad
  /// disponible y aprobada, no ser el dueño y no tener ya otra solicitud
  /// activa para la misma propiedad.
  Future<RentalRequest> enviar({
    required AppUser? arrendatario,
    required Listing propiedad,
    required DurationOption opcion,
    required DateTime fechaIngreso,
    required String mensaje,
    required String metodoPago,
  }) async {
    if (arrendatario == null) {
      throw const RentiException('Inicia sesión para enviar una solicitud.');
    }
    if (!arrendatario.esArrendatario) {
      throw const RentiException(
          'Solo los estudiantes (arrendatarios) pueden solicitar una renta.');
    }
    if (!arrendatario.activo) {
      throw const RentiException('Tu cuenta está suspendida.');
    }
    if (propiedad.ownerId == arrendatario.uid) {
      throw const RentiException('No puedes solicitar tu propia propiedad.');
    }
    final errores = [
      Validators.fechaIngreso(fechaIngreso),
      Validators.mensajeSolicitud(mensaje),
    ].whereType<String>();
    if (errores.isNotEmpty) throw RentiException(errores.first);

    // La propiedad se vuelve a leer del servidor: la copia local pudo cambiar.
    final actual = await _fs
        .collection(Coleccion.propiedades)
        .doc(propiedad.id)
        .get();
    if (!actual.exists) {
      throw const RentiException('Esta propiedad ya no existe.');
    }
    final fresca = Listing.fromMap(actual.data()!, id: actual.id);
    if (!fresca.isPublic) {
      throw const RentiException('Esta propiedad ya no está disponible.');
    }

    final id = RentalRequest.buildId(arrendatario.uid, fresca.id);
    final ref = _sol.doc(id);
    final previa = await ref.get();
    if (previa.exists) {
      final estado = (previa.data()?['estado'] ?? '').toString();
      if (EstadoSolicitud.activas.contains(estado)) {
        throw RentiException(estado == EstadoSolicitud.aceptada
            ? 'Ya tienes una solicitud aceptada para esta propiedad.'
            : 'Ya enviaste una solicitud para esta propiedad. '
                'Espera la respuesta del arrendador.');
      }
    }

    final ahora = DateTime.now();
    final solicitud = RentalRequest(
      id: id,
      listingId: fresca.id,
      listingTitle: fresca.title,
      tenantId: arrendatario.uid,
      tenantName: arrendatario.nombre,
      landlordId: fresca.ownerId,
      months: opcion.months,
      monthlyPrice: opcion.pricePerMonth,
      entryDate: fechaIngreso,
      message: Validators.normalizarEspacios(mensaje),
      paymentMethod: metodoPago,
      createdAt: ahora,
      updatedAt: ahora,
    );
    await ref.set(solicitud.toMap());
    await _guardarSolicitudes([solicitud]);
    return solicitud;
  }

  // ---------------------------------------------------------- consultas

  Future<Resultado<List<RentalRequest>>> delArrendatario(String uid) =>
      _solicitudes('arrendatarioId', 'arrendatario_id', uid);

  Future<Resultado<List<RentalRequest>>> delArrendador(String uid) =>
      _solicitudes('arrendadorId', 'arrendador_id', uid);

  Future<Resultado<List<RentalRequest>>> _solicitudes(
      String campo, String columna, String uid) {
    return remotoOLocal<List<RentalRequest>>(() async {
      final snap = await _sol.where(campo, isEqualTo: uid).get();
      final lista = snap.docs
          .map((d) => RentalRequest.fromMap(d.data(), id: d.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await cacheSegura(() async {
        final db = await AppDatabase.instance.database;
        await db.transaction((txn) async {
          await txn.delete('solicitudes_arrendamiento',
              where: '$columna = ?', whereArgs: [uid]);
          for (final s in lista) {
            await AppDatabase.upsert(txn, 'solicitudes_arrendamiento', s.toRow());
          }
        });
      });
      return lista;
    }, () async {
      final db = await AppDatabase.instance.database;
      final filas = await db.query(
        'solicitudes_arrendamiento',
        where: '$columna = ?',
        whereArgs: [uid],
        orderBy: 'creado_en DESC',
      );
      return filas.map(RentalRequest.fromMap).toList();
    });
  }

  Future<Resultado<List<Rental>>> arrendamientosDe(
      String uid, {required bool comoArrendador}) {
    final campo = comoArrendador ? 'arrendadorId' : 'arrendatarioId';
    final columna = comoArrendador ? 'arrendador_id' : 'arrendatario_id';
    return remotoOLocal<List<Rental>>(() async {
      final snap = await _arr.where(campo, isEqualTo: uid).get();
      final lista = snap.docs
          .map((d) => Rental.fromMap(d.data(), id: d.id))
          .toList()
        ..sort((a, b) => b.start.compareTo(a.start));
      await cacheSegura(() async {
        final db = await AppDatabase.instance.database;
        await db.transaction((txn) async {
          await txn.delete('arrendamientos',
              where: '$columna = ?', whereArgs: [uid]);
          for (final r in lista) {
            await AppDatabase.upsert(txn, 'arrendamientos', r.toRow());
          }
        });
      });
      return lista;
    }, () async {
      final db = await AppDatabase.instance.database;
      final filas = await db.query(
        'arrendamientos',
        where: '$columna = ?',
        whereArgs: [uid],
        orderBy: 'fecha_inicio DESC',
      );
      return filas.map(Rental.fromMap).toList();
    });
  }

  // ----------------------------------------------------------- respuestas

  /// El arrendador acepta o rechaza. Al aceptar, en una sola transacción:
  /// la solicitud pasa a ACEPTADA, se crea el arrendamiento, la propiedad
  /// queda "rentada" y las demás solicitudes pendientes se rechazan.
  Future<Rental?> responder({
    required AppUser? arrendador,
    required RentalRequest solicitud,
    required bool aceptar,
  }) async {
    if (arrendador == null || !arrendador.esArrendador || !arrendador.activo) {
      throw const RentiException(
          'Solo un arrendador activo puede responder solicitudes.');
    }
    if (solicitud.landlordId != arrendador.uid) {
      throw const RentiException(
          'Esta solicitud pertenece a otro arrendador.');
    }

    // Otras solicitudes pendientes para la misma propiedad (se rechazan al
    // aceptar). La consulta no puede hacerse dentro de la transacción.
    final otras = aceptar
        ? await _sol
            .where('arrendadorId', isEqualTo: arrendador.uid)
            .where('propiedadId', isEqualTo: solicitud.listingId)
            .where('estado', isEqualTo: EstadoSolicitud.pendiente)
            .get()
        : null;

    final refSol = _sol.doc(solicitud.id);
    final refProp =
        _fs.collection(Coleccion.propiedades).doc(solicitud.listingId);
    final refArr = _arr.doc(solicitud.id);
    final nuevoEstado =
        aceptar ? EstadoSolicitud.aceptada : EstadoSolicitud.rechazada;
    Rental? arrendamiento;

    await _fs.runTransaction((tx) async {
      final s = await tx.get(refSol);
      if (!s.exists) throw const RentiException('La solicitud ya no existe.');
      if (s.data()?['estado'] != EstadoSolicitud.pendiente) {
        throw const RentiException('Esta solicitud ya fue respondida.');
      }
      final ahora = ahoraIso();
      if (aceptar) {
        final p = await tx.get(refProp);
        if (!p.exists) {
          throw const RentiException('La propiedad ya no existe.');
        }
        final prop = Listing.fromMap(p.data()!, id: p.id);
        if (prop.status != ListingStatus.disponible) {
          throw const RentiException('La propiedad ya está rentada.');
        }
        if (!prop.isApproved) {
          throw const RentiException(
              'La propiedad aún no está aprobada por el administrador.');
        }
        final fin = solicitud.exitDate;
        final nuevoArr = Rental(
          id: solicitud.id,
          requestId: solicitud.id,
          listingId: prop.id,
          listingTitle: prop.title,
          address: prop.address,
          landlordId: arrendador.uid,
          landlordName: arrendador.nombre,
          tenantId: solicitud.tenantId,
          tenantName: solicitud.tenantName,
          start: solicitud.entryDate,
          end: fin,
          months: solicitud.months,
          monthlyPrice: solicitud.monthlyPrice,
        );
        arrendamiento = nuevoArr;
        tx.set(refArr, nuevoArr.toMap());
        tx.update(refProp, {
          'estado': ListingStatus.rentado.name,
          'actualizadoEn': ahora,
        });
        for (final o in otras!.docs) {
          if (o.id != solicitud.id) {
            tx.update(o.reference, {
              'estado': EstadoSolicitud.rechazada,
              'actualizadoEn': ahora,
            });
          }
        }
      }
      tx.update(refSol, {'estado': nuevoEstado, 'actualizadoEn': ahora});
    });

    await _guardarSolicitudes([solicitud.copyWith(status: nuevoEstado)]);
    if (arrendamiento != null) {
      final a = arrendamiento!;
      await cacheSegura(() async {
        final db = await AppDatabase.instance.database;
        await AppDatabase.upsert(db, 'arrendamientos', a.toRow());
      });
    }
    return arrendamiento;
  }

  /// El estudiante cancela una solicitud que sigue pendiente.
  Future<void> cancelar(AppUser? arrendatario, RentalRequest s) async {
    if (arrendatario == null || s.tenantId != arrendatario.uid) {
      throw const RentiException('Solo puedes cancelar tus propias solicitudes.');
    }
    if (!s.isPending) {
      throw const RentiException('Solo se pueden cancelar solicitudes pendientes.');
    }
    await _sol.doc(s.id).update({
      'estado': EstadoSolicitud.cancelada,
      'actualizadoEn': ahoraIso(),
    });
    await _guardarSolicitudes([s.copyWith(status: EstadoSolicitud.cancelada)]);
  }

  /// El arrendador finaliza el arrendamiento y la propiedad vuelve a estar
  /// disponible.
  Future<Rental> finalizar(AppUser? arrendador, Rental r) async {
    if (arrendador == null || r.landlordId != arrendador.uid) {
      throw const RentiException('Solo el arrendador puede finalizar la renta.');
    }
    if (r.state == RentalState.finalizada) return r;
    final ahora = ahoraIso();
    final batch = _fs.batch();
    batch.update(_arr.doc(r.id), {
      'estado': EstadoArrendamiento.finalizada,
      'actualizadoEn': ahora,
    });
    batch.update(_fs.collection(Coleccion.propiedades).doc(r.listingId), {
      'estado': ListingStatus.disponible.name,
      'actualizadoEn': ahora,
    });
    await batch.commit();
    final nuevo = r.copyWith(state: RentalState.finalizada);
    await cacheSegura(() async {
      final db = await AppDatabase.instance.database;
      await AppDatabase.upsert(db, 'arrendamientos', nuevo.toRow());
    });
    return nuevo;
  }

  // ------------------------------------------------------------ supervisión

  /// Solo administrador.
  Future<List<RentalRequest>> todasLasSolicitudes() async {
    final snap = await _sol.limit(200).get();
    return snap.docs
        .map((d) => RentalRequest.fromMap(d.data(), id: d.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Solo administrador.
  Future<List<Rental>> todosLosArrendamientos() async {
    final snap = await _arr.limit(200).get();
    return snap.docs.map((d) => Rental.fromMap(d.data(), id: d.id)).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
  }

  // ----------------------------------------------------------------- SQLite

  Future<void> _guardarSolicitudes(List<RentalRequest> lista) =>
      cacheSegura(() async {
        final db = await AppDatabase.instance.database;
        await db.transaction((txn) async {
          for (final s in lista) {
            await AppDatabase.upsert(txn, 'solicitudes_arrendamiento', s.toRow());
          }
        });
      });
}

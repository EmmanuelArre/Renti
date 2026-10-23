import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Resultado de una lectura que puede venir de la nube o de la caché SQLite.
class Resultado<T> {
  final T datos;

  /// `true` si no se pudo llegar a Firestore y se usó la copia local.
  final bool desdeCache;
  const Resultado(this.datos, {this.desdeCache = false});
}

/// Intenta leer de Firestore; si no hay red (o tarda demasiado) usa [local].
/// Los errores de permisos se propagan: no se esconden detrás de la caché.
Future<Resultado<T>> remotoOLocal<T>(
  Future<T> Function() remoto,
  Future<T> Function() local, {
  Duration espera = const Duration(seconds: 10),
}) async {
  try {
    return Resultado(await remoto().timeout(espera));
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied' || e.code == 'unauthenticated') rethrow;
    return Resultado(await local(), desdeCache: true);
  } on TimeoutException {
    return Resultado(await local(), desdeCache: true);
  }
}

/// Ejecuta una escritura en la caché local sin romper el flujo principal:
/// la caché es secundaria y nunca debe impedir que la operación remota
/// (que ya se completó) se considere exitosa.
Future<void> cacheSegura(Future<void> Function() accion) async {
  try {
    await accion();
  } catch (_) {
    // Caché local no disponible o inconsistente: se reconstruye en la
    // siguiente sincronización.
  }
}

String ahoraIso() => DateTime.now().toUtc().toIso8601String();

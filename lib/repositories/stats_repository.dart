import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:renti/core/constants/app_constants.dart';

/// Estadísticas generales del sistema (solo administrador).
class Estadisticas {
  final int usuarios;
  final int arrendadores;
  final int arrendatarios;
  final int propiedades;
  final int propiedadesPendientes;
  final int propiedadesAprobadas;
  final int propiedadesDesactivadas;
  final int solicitudes;
  final int solicitudesPendientes;
  final int solicitudesAceptadas;
  final int arrendamientosActivos;
  final int reportesAbiertos;

  const Estadisticas({
    this.usuarios = 0,
    this.arrendadores = 0,
    this.arrendatarios = 0,
    this.propiedades = 0,
    this.propiedadesPendientes = 0,
    this.propiedadesAprobadas = 0,
    this.propiedadesDesactivadas = 0,
    this.solicitudes = 0,
    this.solicitudesPendientes = 0,
    this.solicitudesAceptadas = 0,
    this.arrendamientosActivos = 0,
    this.reportesAbiertos = 0,
  });

  /// Porcentaje de solicitudes aceptadas (0–100).
  int get tasaAceptacion =>
      solicitudes == 0 ? 0 : (solicitudesAceptadas * 100 / solicitudes).round();
}

class StatsRepository {
  StatsRepository._();
  static final StatsRepository instance = StatsRepository._();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;

  Future<int> _contar(Query<Map<String, dynamic>> q) async {
    final r = await q.count().get();
    return r.count ?? 0;
  }

  Future<Estadisticas> cargar() async {
    final u = _fs.collection(Coleccion.usuarios);
    final p = _fs.collection(Coleccion.propiedades);
    final s = _fs.collection(Coleccion.solicitudes);
    final a = _fs.collection(Coleccion.arrendamientos);
    final r = _fs.collection(Coleccion.reportes);

    final v = await Future.wait<int>([
      _contar(u),
      _contar(u.where('rol', isEqualTo: Roles.arrendador)),
      _contar(u.where('rol', isEqualTo: Roles.arrendatario)),
      _contar(p),
      _contar(p.where('moderacion', isEqualTo: Moderacion.pendiente)),
      _contar(p.where('moderacion', isEqualTo: Moderacion.aprobada)),
      _contar(p.where('moderacion', isEqualTo: Moderacion.desactivada)),
      _contar(s),
      _contar(s.where('estado', isEqualTo: EstadoSolicitud.pendiente)),
      _contar(s.where('estado', isEqualTo: EstadoSolicitud.aceptada)),
      _contar(a.where('estado', isEqualTo: EstadoArrendamiento.activa)),
      _contar(r.where('estado', isEqualTo: EstadoReporte.abierto)),
    ]);
    return Estadisticas(
      usuarios: v[0],
      arrendadores: v[1],
      arrendatarios: v[2],
      propiedades: v[3],
      propiedadesPendientes: v[4],
      propiedadesAprobadas: v[5],
      propiedadesDesactivadas: v[6],
      solicitudes: v[7],
      solicitudesPendientes: v[8],
      solicitudesAceptadas: v[9],
      arrendamientosActivos: v[10],
      reportesAbiertos: v[11],
    );
  }
}

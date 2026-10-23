import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/services/data_source.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/models/app_user.dart';
import 'package:renti/models/report.dart';

/// Reportes de propiedades y de personas. Firestore: `reportes`.
class ReportRepository {
  ReportRepository._();
  static final ReportRepository instance = ReportRepository._();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection(Coleccion.reportes);

  Future<Report> crear({
    required AppUser? autor,
    required String tipo,
    required String objetivoId,
    required String objetivoNombre,
    required String motivo,
    required String detalle,
  }) async {
    if (autor == null) {
      throw const RentiException('Inicia sesión para enviar un reporte.');
    }
    final error =
        Validators.motivoReporte(motivo) ?? Validators.detalleReporte(detalle);
    if (error != null) throw RentiException(error);
    if (tipo == TipoReporte.usuario && objetivoId == autor.uid) {
      throw const RentiException('No puedes reportarte a ti mismo.');
    }
    final ref = _col.doc();
    final r = Report(
      id: ref.id,
      type: tipo,
      targetId: objetivoId,
      targetName: objetivoNombre,
      reporterId: autor.uid,
      reporterName: autor.nombre,
      reason: motivo,
      details: Validators.normalizarEspacios(detalle),
    );
    await ref.set(r.toMap());
    return r;
  }

  /// Solo administrador.
  Future<List<Report>> todos() async {
    final snap = await _col.limit(300).get();
    return snap.docs.map((d) => Report.fromMap(d.data(), id: d.id)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Solo administrador: marca el reporte como resuelto o descartado.
  Future<void> resolver(String id, String estado, String resolucion) async {
    if (estado != EstadoReporte.resuelto && estado != EstadoReporte.descartado) {
      throw const RentiException('Estado de reporte no válido.');
    }
    await _col.doc(id).update({
      'estado': estado,
      'resolucion': Validators.normalizarEspacios(resolucion),
      'actualizadoEn': ahoraIso(),
    });
  }
}

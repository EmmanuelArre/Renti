import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/models/model_utils.dart';

/// Reporte de una propiedad o de una persona. Documento `reportes/{id}`.
class Report {
  final String id;
  final String type; // propiedad | usuario
  final String targetId;
  final String targetName;
  final String reporterId;
  final String reporterName;
  final String reason;
  final String details;
  final String status; // abierto | resuelto | descartado
  final String resolution;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.type,
    required this.targetId,
    required this.targetName,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    required this.details,
    this.status = EstadoReporte.abierto,
    this.resolution = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isOpen => status == EstadoReporte.abierto;

  Map<String, Object?> toMap() => {
        'tipo': type,
        'objetivoId': targetId,
        'objetivoNombre': targetName,
        'reportanteId': reporterId,
        'reportanteNombre': reporterName,
        'motivo': reason,
        'detalle': details,
        'estado': status,
        'resolucion': resolution,
        'creadoEn': iso(createdAt),
        'actualizadoEn': iso(updatedAt),
      };

  factory Report.fromMap(Map<String, Object?> m, {String? id}) => Report(
        id: id ?? asString(m['id']),
        type: asString(m['tipo'], TipoReporte.propiedad),
        targetId: asString(m['objetivoId']),
        targetName: asString(m['objetivoNombre']),
        reporterId: asString(m['reportanteId']),
        reporterName: asString(m['reportanteNombre']),
        reason: asString(m['motivo']),
        details: asString(m['detalle']),
        status: asString(m['estado'], EstadoReporte.abierto),
        resolution: asString(m['resolucion']),
        createdAt: asDate(m['creadoEn']),
        updatedAt: asDate(m['actualizadoEn']),
      );
}

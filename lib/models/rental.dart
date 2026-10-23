import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/models/model_utils.dart';

enum RentalState { activa, finalizada }

/// Arrendamiento vigente o pasado. Se crea cuando el arrendador acepta una
/// solicitud. Documento `arrendamientos/{id}` (mismo id que la solicitud).
class Rental {
  final String id;
  final String requestId;
  final String listingId;
  final String listingTitle;
  final String address;
  final String landlordId;
  final String landlordName;
  final String tenantId;
  final String tenantName;
  final DateTime start;
  final DateTime end;
  final int months; // 0 = indefinido
  final int monthlyPrice;
  final RentalState state;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rental({
    required this.id,
    String? requestId,
    required this.listingId,
    required this.listingTitle,
    this.address = '',
    required this.landlordId,
    this.landlordName = '',
    required this.tenantId,
    this.tenantName = '',
    required this.start,
    required this.end,
    required this.months,
    required this.monthlyPrice,
    this.state = RentalState.activa,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : requestId = requestId ?? id,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Rental copyWith({RentalState? state}) => Rental(
        id: id,
        requestId: requestId,
        listingId: listingId,
        listingTitle: listingTitle,
        address: address,
        landlordId: landlordId,
        landlordName: landlordName,
        tenantId: tenantId,
        tenantName: tenantName,
        start: start,
        end: end,
        months: months,
        monthlyPrice: monthlyPrice,
        state: state ?? this.state,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, Object?> toMap() => {
        'solicitudId': requestId,
        'propiedadId': listingId,
        'tituloPropiedad': listingTitle,
        'direccion': address,
        'arrendadorId': landlordId,
        'arrendadorNombre': landlordName,
        'arrendatarioId': tenantId,
        'arrendatarioNombre': tenantName,
        'fechaInicio': iso(start),
        'fechaFin': iso(end),
        'meses': months,
        'precioMensual': monthlyPrice,
        'estado': state.name,
        'creadoEn': iso(createdAt),
        'actualizadoEn': iso(updatedAt),
      };

  Map<String, Object?> toRow() => {
        'id': id,
        'solicitud_id': requestId,
        'propiedad_id': listingId,
        'titulo_propiedad': listingTitle,
        'direccion': address,
        'arrendador_id': landlordId,
        'arrendador_nombre': landlordName,
        'arrendatario_id': tenantId,
        'arrendatario_nombre': tenantName,
        'fecha_inicio': iso(start),
        'fecha_fin': iso(end),
        'meses': months,
        'precio_mensual': monthlyPrice,
        'estado': state.name,
        'creado_en': iso(createdAt),
        'actualizado_en': iso(updatedAt),
      };

  factory Rental.fromMap(Map<String, Object?> m, {String? id}) => Rental(
        id: id ?? asString(m['id']),
        requestId: asString(m['solicitudId'] ?? m['solicitud_id']),
        listingId: asString(m['propiedadId'] ?? m['propiedad_id']),
        listingTitle: asString(m['tituloPropiedad'] ?? m['titulo_propiedad']),
        address: asString(m['direccion']),
        landlordId: asString(m['arrendadorId'] ?? m['arrendador_id']),
        landlordName: asString(m['arrendadorNombre'] ?? m['arrendador_nombre']),
        tenantId: asString(m['arrendatarioId'] ?? m['arrendatario_id']),
        tenantName: asString(m['arrendatarioNombre'] ?? m['arrendatario_nombre']),
        start: asDate(m['fechaInicio'] ?? m['fecha_inicio']),
        end: asDate(m['fechaFin'] ?? m['fecha_fin']),
        months: asInt(m['meses']),
        monthlyPrice: asInt(m['precioMensual'] ?? m['precio_mensual']),
        state: asString(m['estado']) == EstadoArrendamiento.finalizada
            ? RentalState.finalizada
            : RentalState.activa,
        createdAt: asDate(m['creadoEn'] ?? m['creado_en']),
        updatedAt: asDate(m['actualizadoEn'] ?? m['actualizado_en']),
      );
}

/// Solicitud de arrendamiento enviada por un estudiante.
/// Documento `solicitudes/{arrendatarioId}_{propiedadId}`.
class RentalRequest {
  final String id;
  final String listingId;
  final String listingTitle;
  final String tenantId;
  final String tenantName;
  final String landlordId;
  final int months; // 0 = indefinido
  final int monthlyPrice;
  final DateTime entryDate;
  final String message;
  final String paymentMethod;
  final String status; // PENDIENTE / ACEPTADA / RECHAZADA / CANCELADA
  final DateTime createdAt;
  final DateTime updatedAt;

  RentalRequest({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.tenantId,
    required this.tenantName,
    required this.landlordId,
    required this.months,
    required this.monthlyPrice,
    required this.entryDate,
    this.message = '',
    this.paymentMethod = 'Efectivo',
    this.status = EstadoSolicitud.pendiente,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Id determinista: garantiza una sola solicitud por estudiante y propiedad.
  static String buildId(String tenantId, String listingId) =>
      '${tenantId}_$listingId';

  bool get isPending => status == EstadoSolicitud.pendiente;
  bool get isActive => EstadoSolicitud.activas.contains(status);

  /// Fecha de salida calculada (indefinido = 12 meses renovables).
  DateTime get exitDate {
    final m = months == 0 ? 12 : months;
    final d = DateTime(entryDate.year, entryDate.month + m, entryDate.day);
    return d.subtract(const Duration(days: 1));
  }

  RentalRequest copyWith({String? status}) => RentalRequest(
        id: id,
        listingId: listingId,
        listingTitle: listingTitle,
        tenantId: tenantId,
        tenantName: tenantName,
        landlordId: landlordId,
        months: months,
        monthlyPrice: monthlyPrice,
        entryDate: entryDate,
        message: message,
        paymentMethod: paymentMethod,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, Object?> toMap() => {
        'propiedadId': listingId,
        'tituloPropiedad': listingTitle,
        'arrendatarioId': tenantId,
        'arrendatarioNombre': tenantName,
        'arrendadorId': landlordId,
        'meses': months,
        'precioMensual': monthlyPrice,
        'fechaIngreso': iso(entryDate),
        'mensaje': message,
        'metodoPago': paymentMethod,
        'estado': status,
        'creadoEn': iso(createdAt),
        'actualizadoEn': iso(updatedAt),
      };

  Map<String, Object?> toRow() => {
        'id': id,
        'propiedad_id': listingId,
        'titulo_propiedad': listingTitle,
        'arrendatario_id': tenantId,
        'arrendatario_nombre': tenantName,
        'arrendador_id': landlordId,
        'meses': months,
        'precio_mensual': monthlyPrice,
        'fecha_ingreso': iso(entryDate),
        'mensaje': message,
        'metodo_pago': paymentMethod,
        'estado': status,
        'creado_en': iso(createdAt),
        'actualizado_en': iso(updatedAt),
      };

  factory RentalRequest.fromMap(Map<String, Object?> m, {String? id}) =>
      RentalRequest(
        id: id ?? asString(m['id']),
        listingId: asString(m['propiedadId'] ?? m['propiedad_id']),
        listingTitle: asString(m['tituloPropiedad'] ?? m['titulo_propiedad']),
        tenantId: asString(m['arrendatarioId'] ?? m['arrendatario_id']),
        tenantName: asString(m['arrendatarioNombre'] ?? m['arrendatario_nombre']),
        landlordId: asString(m['arrendadorId'] ?? m['arrendador_id']),
        months: asInt(m['meses']),
        monthlyPrice: asInt(m['precioMensual'] ?? m['precio_mensual']),
        entryDate: asDate(m['fechaIngreso'] ?? m['fecha_ingreso']),
        message: asString(m['mensaje']),
        paymentMethod: asString(m['metodoPago'] ?? m['metodo_pago'], 'Efectivo'),
        status: asString(m['estado'], EstadoSolicitud.pendiente),
        createdAt: asDate(m['creadoEn'] ?? m['creado_en']),
        updatedAt: asDate(m['actualizadoEn'] ?? m['actualizado_en']),
      );
}

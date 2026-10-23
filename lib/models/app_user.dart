import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/models/model_utils.dart';

/// Perfil de una persona usuaria. El documento vive en `usuarios/{uid}`
/// (Firestore) y se cachea en la tabla `usuarios` de SQLite.
///
/// Las credenciales NO se guardan aquí: las administra Firebase Auth.
class AppUser {
  final String uid;
  final String nombre;
  final String email;
  final String rol;
  final String universidad;
  final String telefono;
  final String estado;
  final String proveedor; // password | google.com
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  AppUser({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    this.universidad = '',
    this.telefono = '',
    this.estado = EstadoCuenta.activo,
    this.proveedor = 'password',
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  })  : creadoEn = creadoEn ?? DateTime.now(),
        actualizadoEn = actualizadoEn ?? DateTime.now();

  bool get esArrendador => rol == Roles.arrendador;
  bool get esArrendatario => rol == Roles.arrendatario;
  bool get esAdmin => rol == Roles.administrador;
  bool get activo => estado == EstadoCuenta.activo;

  String get iniciales => inicialesDe(nombre);

  AppUser copyWith({
    String? nombre,
    String? rol,
    String? universidad,
    String? telefono,
    String? estado,
    DateTime? actualizadoEn,
  }) =>
      AppUser(
        uid: uid,
        nombre: nombre ?? this.nombre,
        email: email,
        rol: rol ?? this.rol,
        universidad: universidad ?? this.universidad,
        telefono: telefono ?? this.telefono,
        estado: estado ?? this.estado,
        proveedor: proveedor,
        creadoEn: creadoEn,
        actualizadoEn: actualizadoEn ?? DateTime.now(),
      );

  /// Mapa compartido por Firestore y SQLite (solo tipos primitivos).
  Map<String, Object?> toMap() => {
        'uid': uid,
        'nombre': nombre,
        'email': email,
        'rol': rol,
        'universidad': universidad,
        'telefono': telefono,
        'estado': estado,
        'proveedor': proveedor,
        'creadoEn': creadoEn.toUtc().toIso8601String(),
        'actualizadoEn': actualizadoEn.toUtc().toIso8601String(),
      };

  Map<String, Object?> toRow() => {
        'uid': uid,
        'nombre': nombre,
        'email': email,
        'rol': rol,
        'universidad': universidad,
        'telefono': telefono,
        'estado': estado,
        'proveedor': proveedor,
        'creado_en': creadoEn.toUtc().toIso8601String(),
        'actualizado_en': actualizadoEn.toUtc().toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, Object?> m, {String? uid}) => AppUser(
        uid: uid ?? asString(m['uid']),
        nombre: asString(m['nombre']),
        email: asString(m['email']),
        rol: asString(m['rol'], Roles.arrendatario),
        universidad: asString(m['universidad']),
        telefono: asString(m['telefono']),
        estado: asString(m['estado'], EstadoCuenta.activo),
        proveedor: asString(m['proveedor'], 'password'),
        creadoEn: asDate(m['creadoEn'] ?? m['creado_en']),
        actualizadoEn: asDate(m['actualizadoEn'] ?? m['actualizado_en']),
      );
}

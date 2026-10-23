/// Constantes de dominio de Renti: roles, estados, nombres de colecciones y
/// catálogos (universidades, tipos de propiedad, servicios).
library;

/// Roles de la aplicación. Se guardan en `usuarios/{uid}.rol`.
///
/// El rol [administrador] NO se puede elegir al registrarse: se concede
/// creando a mano el documento `admins/{uid}` en Firestore (ver README).
class Roles {
  static const arrendador = 'arrendador';
  static const arrendatario = 'arrendatario';
  static const administrador = 'administrador';

  /// Roles que una persona puede elegir al crear su cuenta.
  static const registrables = [arrendatario, arrendador];

  static bool esRegistrable(String? rol) => registrables.contains(rol);

  static String etiqueta(String rol) {
    switch (rol) {
      case arrendador:
        return 'Arrendador';
      case administrador:
        return 'Administrador';
      case arrendatario:
      default:
        return 'Estudiante';
    }
  }
}

class EstadoCuenta {
  static const activo = 'activo';
  static const suspendido = 'suspendido';
}

/// Estado de moderación de una publicación (lo cambia el administrador).
class Moderacion {
  static const pendiente = 'pendiente';
  static const aprobada = 'aprobada';
  static const rechazada = 'rechazada';
  static const desactivada = 'desactivada';
  static const todos = [pendiente, aprobada, rechazada, desactivada];

  static String etiqueta(String m) {
    switch (m) {
      case aprobada:
        return 'APROBADA';
      case rechazada:
        return 'RECHAZADA';
      case desactivada:
        return 'DESACTIVADA';
      case pendiente:
      default:
        return 'EN REVISIÓN';
    }
  }
}

class EstadoSolicitud {
  static const pendiente = 'PENDIENTE';
  static const aceptada = 'ACEPTADA';
  static const rechazada = 'RECHAZADA';
  static const cancelada = 'CANCELADA';

  /// Una solicitud "activa" bloquea que el mismo usuario envíe otra igual.
  static const activas = [pendiente, aceptada];
}

class EstadoArrendamiento {
  static const activa = 'activa';
  static const finalizada = 'finalizada';
}

class EstadoReporte {
  static const abierto = 'abierto';
  static const resuelto = 'resuelto';
  static const descartado = 'descartado';
}

class TipoReporte {
  static const propiedad = 'propiedad';
  static const usuario = 'usuario';
}

/// Nombres de colecciones de Firestore.
class Coleccion {
  static const usuarios = 'usuarios';
  static const admins = 'admins';
  static const propiedades = 'propiedades';
  static const imagenes = 'imagenes';
  static const favoritos = 'favoritos';
  static const solicitudes = 'solicitudes';
  static const arrendamientos = 'arrendamientos';
  static const reportes = 'reportes';
  static const notificaciones = 'notificaciones';
  static const chats = 'chats';
  static const mensajes = 'mensajes';
}

/// Catálogos que antes vivían en `mock_data.dart`.
class Catalogos {
  static const universidades = <String>[
    'UTNG - Universidad Tecnológica del Norte de Guanajuato',
    'UG - Universidad de Guanajuato',
    'ITESI - Instituto Tecnológico Superior',
    'UNAM',
    'Tec de Monterrey',
  ];

  static const tiposPropiedad = <String>[
    'Habitación',
    'Departamento',
    'Casa',
    'Compartido',
  ];

  static const servicios = <String>[
    'Wi-Fi',
    'Agua',
    'Luz',
    'Gas',
    'Amueblado',
    'Cocina',
    'Lavadora',
    'Estacionamiento',
  ];

  static const categorias = <(String, String)>[
    ('🏠', 'Habitación'),
    ('🏢', 'Departamento'),
    ('🏡', 'Casa'),
    ('👥', 'Compartido'),
  ];

  static const motivosReporte = <String>[
    'Información falsa',
    'Precio engañoso',
    'Contenido inapropiado',
    'Posible fraude',
    'Comportamiento indebido',
    'Otro',
  ];

  static const metodosPago = <String>['Efectivo', 'Transferencia'];
}

/// Límites usados tanto por los validadores como por la base de datos.
class Limites {
  static const maxFotos = 4;
  static const maxBytesFoto = 4 * 1024 * 1024; // 4 MB por foto original
  static const extensionesFoto = ['jpg', 'jpeg', 'png', 'webp'];
  static const precioMax = 1000000;
}

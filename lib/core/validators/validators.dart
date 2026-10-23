import 'package:renti/core/constants/app_constants.dart';

/// Validadores puros (sin Flutter) reutilizados por formularios, lógica de
/// negocio y pruebas. Todos devuelven `null` cuando el valor es válido, o el
/// mensaje de error en español.
class Validators {
  Validators._();

  // ---------------------------------------------------------------- limpieza

  /// Quita espacios al inicio/final y colapsa espacios repetidos.
  static String normalizarEspacios(String? v) =>
      (v ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');

  static String normalizarCorreo(String? v) => (v ?? '').trim().toLowerCase();

  /// Convierte "\$3,500" o "3 500" en 3500. Devuelve null si no hay dígitos
  /// o si el texto contiene caracteres que no sean dígitos/separadores.
  static int? parsearEntero(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    if (!RegExp(r'^[\$\s,.\d]+$').hasMatch(t)) return null;
    final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  // ------------------------------------------------------------- formulario

  static String? obligatorio(String? v, [String campo = 'Este campo']) {
    if (normalizarEspacios(v).isEmpty) return '$campo es obligatorio';
    return null;
  }

  static String? nombreCompleto(String? v) {
    final t = normalizarEspacios(v);
    if (t.isEmpty) return 'El nombre completo es obligatorio';
    if (t.length < 3) return 'El nombre es demasiado corto';
    if (t.length > 60) return 'El nombre no puede tener más de 60 caracteres';
    if (!RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ][A-Za-zÁÉÍÓÚÜÑáéíóúüñ .'\-]*$").hasMatch(t)) {
      return 'Usa solo letras, espacios, punto, guion o apóstrofo';
    }
    if (!t.contains(' ')) return 'Escribe tu nombre y apellido';
    return null;
  }

  static final _correo = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$',
  );

  static String? correo(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'El correo electrónico es obligatorio';
    if (t.length > 120 || !_correo.hasMatch(t)) {
      return 'Escribe un correo válido, ej. nombre@correo.com';
    }
    return null;
  }

  /// Contraseña: mínimo 8 caracteres con mayúscula, minúscula y número.
  static String? contrasena(String? v) {
    final t = v ?? '';
    if (t.isEmpty) return 'La contraseña es obligatoria';
    if (t.length < 8) return 'Debe tener al menos 8 caracteres';
    if (t.length > 64) return 'No puede tener más de 64 caracteres';
    if (t.contains(' ')) return 'No puede contener espacios';
    if (!RegExp(r'[a-z]').hasMatch(t)) return 'Incluye al menos una minúscula';
    if (!RegExp(r'[A-Z]').hasMatch(t)) return 'Incluye al menos una mayúscula';
    if (!RegExp(r'\d').hasMatch(t)) return 'Incluye al menos un número';
    return null;
  }

  static String? confirmarContrasena(String? v, String? original) {
    if ((v ?? '').isEmpty) return 'Confirma tu contraseña';
    if (v != original) return 'Las contraseñas no coinciden';
    return null;
  }

  /// Teléfono opcional: si se escribe debe tener 10 dígitos.
  static String? telefonoOpcional(String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
    if (d.isEmpty) return null;
    if (!RegExp(r'^\d{10}$').hasMatch(d)) return 'Escribe un teléfono de 10 dígitos';
    return null;
  }

  static String? rol(String? v) {
    if (!Roles.esRegistrable(v)) return 'Selecciona cómo quieres usar Renti';
    return null;
  }

  // ------------------------------------------------------------ propiedades

  static String? tituloPropiedad(String? v) {
    final t = normalizarEspacios(v);
    if (t.isEmpty) return 'El nombre es obligatorio';
    if (t.length < 3) return 'Debe tener al menos 3 caracteres';
    if (t.length > 60) return 'No puede tener más de 60 caracteres';
    return null;
  }

  static String? tipoPropiedad(String? v) {
    if (v == null || !Catalogos.tiposPropiedad.contains(v)) {
      return 'Selecciona el tipo de propiedad';
    }
    return null;
  }

  static String? direccion(String? v) {
    final t = normalizarEspacios(v);
    if (t.isEmpty) return 'La dirección es obligatoria';
    if (t.length < 8) return 'Escribe calle, número y colonia';
    if (t.length > 120) return 'La dirección es demasiado larga';
    if (!RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(t)) {
      return 'La dirección debe incluir el nombre de la calle';
    }
    return null;
  }

  static String? ubicacion(String? v) {
    final t = normalizarEspacios(v);
    if (t.isEmpty) return 'La ubicación o referencia es obligatoria';
    if (t.length < 3) return 'Escribe una referencia, ej. "A 800 m de la UTNG"';
    if (t.length > 80) return 'No puede tener más de 80 caracteres';
    return null;
  }

  static String? descripcion(String? v) {
    final t = normalizarEspacios(v);
    if (t.isEmpty) return 'La descripción es obligatoria';
    if (t.length < 20) return 'Describe el espacio con al menos 20 caracteres';
    if (t.length > 1000) return 'No puede tener más de 1000 caracteres';
    return null;
  }

  static String? precio(String? v) {
    final n = parsearEntero(v);
    if ((v ?? '').trim().isEmpty) return 'El precio mensual es obligatorio';
    if (n == null) return 'Escribe solo números';
    if (n <= 0) return 'El precio debe ser mayor que cero';
    if (n > Limites.precioMax) return 'El precio es demasiado alto';
    return null;
  }

  static String? enteroEnRango(String? v, String campo, int min, int max) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return '$campo es obligatorio';
    final n = int.tryParse(t);
    if (n == null) return 'Escribe un número entero';
    if (n < min || n > max) return '$campo debe estar entre $min y $max';
    return null;
  }

  static String? serviciosSeleccionados(Iterable<String> servicios) {
    if (servicios.isEmpty) return 'Selecciona al menos un servicio';
    return null;
  }

  // --------------------------------------------------------------- imágenes

  static String extension(String ruta) {
    final i = ruta.lastIndexOf('.');
    if (i < 0 || i == ruta.length - 1) return '';
    return ruta.substring(i + 1).toLowerCase();
  }

  static bool formatoImagenValido(String ruta) =>
      Limites.extensionesFoto.contains(extension(ruta));

  static String? foto({required String nombre, required int bytes}) {
    if (!formatoImagenValido(nombre)) {
      return 'Formato no admitido ($nombre). Usa JPG, PNG o WEBP';
    }
    if (bytes > Limites.maxBytesFoto) {
      return 'La foto $nombre pesa más de 4 MB';
    }
    if (bytes == 0) return 'La foto $nombre está vacía';
    return null;
  }

  static String? cantidadFotos(int n) {
    if (n == 0) return 'Agrega al menos una fotografía';
    if (n > Limites.maxFotos) return 'Máximo ${Limites.maxFotos} fotografías';
    return null;
  }

  // ------------------------------------------------------------- solicitudes

  static String? mensajeSolicitud(String? v) {
    final t = normalizarEspacios(v);
    if (t.length > 400) return 'El mensaje no puede tener más de 400 caracteres';
    return null;
  }

  static String? fechaIngreso(DateTime? fecha, {DateTime? hoy}) {
    if (fecha == null) return 'Selecciona la fecha de entrada';
    final base = hoy ?? DateTime.now();
    final h = DateTime(base.year, base.month, base.day);
    final f = DateTime(fecha.year, fecha.month, fecha.day);
    if (f.isBefore(h)) return 'La fecha de entrada no puede estar en el pasado';
    return null;
  }

  static String? motivoReporte(String? v) {
    if (v == null || !Catalogos.motivosReporte.contains(v)) {
      return 'Selecciona un motivo';
    }
    return null;
  }

  static String? detalleReporte(String? v) {
    final t = normalizarEspacios(v);
    if (t.length < 10) return 'Cuéntanos qué pasó (mínimo 10 caracteres)';
    if (t.length > 500) return 'No puede tener más de 500 caracteres';
    return null;
  }
}

/// Error de regla de negocio con un mensaje listo para mostrar al usuario.
class RentiException implements Exception {
  final String message;
  const RentiException(this.message);
  @override
  String toString() => message;
}

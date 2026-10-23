import 'package:flutter_test/flutter_test.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/validators/validators.dart';

void main() {
  group('Nombre', () {
    test('acepta nombre y apellido', () {
      expect(Validators.nombreCompleto('Oscar Ramírez'), isNull);
    });
    test('rechaza vacío, una sola palabra y números', () {
      expect(Validators.nombreCompleto(''), isNotNull);
      expect(Validators.nombreCompleto('Oscar'), isNotNull);
      expect(Validators.nombreCompleto('Oscar 123'), isNotNull);
    });
  });

  group('Correo', () {
    test('acepta correos válidos', () {
      expect(Validators.correo('alumno@utng.edu.mx'), isNull);
      expect(Validators.correo('  a.b+c@correo.com '), isNull);
    });
    test('rechaza correos inválidos', () {
      for (final c in ['', 'sin-arroba', 'a@b', '@correo.com', 'a b@c.com']) {
        expect(Validators.correo(c), isNotNull, reason: c);
      }
    });
  });

  group('Contraseña', () {
    test('acepta una contraseña fuerte', () {
      expect(Validators.contrasena('Abcdef12'), isNull);
    });
    test('rechaza cortas o sin mayúscula/minúscula/número', () {
      expect(Validators.contrasena('Ab1'), isNotNull);
      expect(Validators.contrasena('abcdefg1'), isNotNull);
      expect(Validators.contrasena('ABCDEFG1'), isNotNull);
      expect(Validators.contrasena('Abcdefgh'), isNotNull);
    });
    test('confirmación debe coincidir', () {
      expect(Validators.confirmarContrasena('Abcdef12', 'Abcdef12'), isNull);
      expect(Validators.confirmarContrasena('Abcdef13', 'Abcdef12'), isNotNull);
      expect(Validators.confirmarContrasena('', 'Abcdef12'), isNotNull);
    });
  });

  group('Teléfono y rol', () {
    test('teléfono opcional', () {
      expect(Validators.telefonoOpcional(''), isNull);
      expect(Validators.telefonoOpcional('473 123 4567'), isNull);
      expect(Validators.telefonoOpcional('12345'), isNotNull);
    });
    test('el administrador no es un rol registrable', () {
      expect(Validators.rol(Roles.arrendador), isNull);
      expect(Validators.rol(Roles.arrendatario), isNull);
      expect(Validators.rol(Roles.administrador), isNotNull);
      expect(Validators.rol(null), isNotNull);
    });
  });

  group('Propiedad', () {
    test('precio', () {
      expect(Validators.precio('2500'), isNull);
      expect(Validators.precio(''), isNotNull);
      expect(Validators.precio('0'), isNotNull);
      expect(Validators.precio('abc'), isNotNull);
      expect(Validators.precio('${Limites.precioMax + 1}'), isNotNull);
    });
    test('descripción mínima de 20 caracteres', () {
      expect(Validators.descripcion('corta'), isNotNull);
      expect(Validators.descripcion('Cuarto amplio y luminoso cerca de la escuela'),
          isNull);
    });
    test('tipo debe estar en el catálogo', () {
      expect(Validators.tipoPropiedad(Catalogos.tiposPropiedad.first), isNull);
      expect(Validators.tipoPropiedad('Castillo'), isNotNull);
      expect(Validators.tipoPropiedad(null), isNotNull);
    });
    test('enteros en rango y servicios', () {
      expect(Validators.enteroEnRango('2', 'Baños', 1, 20), isNull);
      expect(Validators.enteroEnRango('0', 'Baños', 1, 20), isNotNull);
      expect(Validators.enteroEnRango('x', 'Baños', 1, 20), isNotNull);
      expect(Validators.serviciosSeleccionados(const []), isNotNull);
      expect(Validators.serviciosSeleccionados(const ['Agua']), isNull);
    });
  });

  group('Fotos', () {
    test('formato y tamaño', () {
      expect(Validators.foto(nombre: 'a.JPG', bytes: 1000), isNull);
      expect(Validators.foto(nombre: 'a.gif', bytes: 1000), isNotNull);
      expect(Validators.foto(nombre: 'a.png', bytes: Limites.maxBytesFoto + 1),
          isNotNull);
      expect(Validators.foto(nombre: 'a.png', bytes: 0), isNotNull);
    });
    test('cantidad', () {
      expect(Validators.cantidadFotos(0), isNotNull);
      expect(Validators.cantidadFotos(1), isNull);
      expect(Validators.cantidadFotos(Limites.maxFotos), isNull);
      expect(Validators.cantidadFotos(Limites.maxFotos + 1), isNotNull);
    });
  });

  group('Solicitud', () {
    final hoy = DateTime(2026, 5, 10);
    test('la fecha de entrada no puede ser pasada', () {
      expect(Validators.fechaIngreso(DateTime(2026, 5, 9), hoy: hoy), isNotNull);
      expect(Validators.fechaIngreso(DateTime(2026, 5, 10, 8), hoy: hoy), isNull);
      expect(Validators.fechaIngreso(DateTime(2026, 6, 1), hoy: hoy), isNull);
      expect(Validators.fechaIngreso(null, hoy: hoy), isNotNull);
    });
    test('mensaje de máximo 400 caracteres', () {
      expect(Validators.mensajeSolicitud(''), isNull);
      expect(Validators.mensajeSolicitud('a' * 401), isNotNull);
    });
  });

  group('Utilidades', () {
    test('normalizarEspacios', () {
      expect(Validators.normalizarEspacios('  Hola   mundo '), 'Hola mundo');
    });
    test('parsearEntero', () {
      expect(Validators.parsearEntero(r'$3,500'), 3500);
      expect(Validators.parsearEntero('abc'), isNull);
      expect(Validators.parsearEntero(''), isNull);
    });
  });
}

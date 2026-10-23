import 'package:flutter_test/flutter_test.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/models/app_user.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/models/rental.dart';
import 'package:renti/models/report.dart';

void main() {
  test('AppUser: ida y vuelta por mapa de Firestore y fila de SQLite', () {
    final u = AppUser(
      uid: 'u1',
      nombre: 'Ana López',
      email: 'ana@correo.com',
      rol: Roles.arrendador,
      universidad: 'UTNG',
    );
    final deMapa = AppUser.fromMap(u.toMap());
    expect(deMapa.uid, 'u1');
    expect(deMapa.esArrendador, isTrue);
    expect(deMapa.activo, isTrue);

    final deFila = AppUser.fromMap(u.toRow());
    expect(deFila.email, 'ana@correo.com');
    expect(deFila.universidad, 'UTNG');
    expect(u.iniciales, 'AL');
  });

  test('AppUser: un rol desconocido cae en arrendatario, nunca en administrador', () {
    final u = AppUser.fromMap({'uid': 'x', 'nombre': 'Sin Rol', 'email': 'a@b.co'});
    expect(u.esAdmin, isFalse);
  });

  group('Listing', () {
    Listing nueva({String moderacion = Moderacion.pendiente}) => Listing(
          id: 'p1',
          ownerId: 'u1',
          title: 'Cuarto cerca',
          type: 'Habitación',
          address: 'Calle Juárez 12',
          distance: 'A 800 m',
          price: 3000,
          services: const ['Agua', 'Internet'],
          landlord: 'Ana López',
          moderation: moderacion,
        );

    test('una publicación nueva está en revisión y no es pública', () {
      final l = nueva();
      expect(l.moderation, Moderacion.pendiente);
      expect(l.isPublic, isFalse);
    });

    test('solo aprobada y disponible es pública', () {
      expect(nueva(moderacion: Moderacion.aprobada).isPublic, isTrue);
      expect(
        nueva(moderacion: Moderacion.aprobada)
            .copyWith(status: ListingStatus.rentado)
            .isPublic,
        isFalse,
      );
    });

    test('toRow/fromMap conserva los datos (servicios como JSON)', () {
      final l = nueva(moderacion: Moderacion.aprobada);
      final copia = Listing.fromMap(l.toRow());
      expect(copia.id, 'p1');
      expect(copia.price, 3000);
      expect(copia.services, ['Agua', 'Internet']);
      expect(copia.moderation, Moderacion.aprobada);
      expect(copia.rating, isNull);
    });

    test('toMap/fromMap (Firestore) usa listas nativas', () {
      final copia = Listing.fromMap(nueva().toMap(), id: 'p1');
      expect(copia.services, ['Agua', 'Internet']);
      expect(copia.ownerId, 'u1');
    });

    test('duraciones con descuento', () {
      final d = nueva().durations;
      expect(d.map((x) => x.months), [1, 3, 6, 0]);
      expect(d[0].pricePerMonth, 3000);
      expect(d[1].pricePerMonth, 2800);
      expect(d[2].pricePerMonth, 2700);
      expect(d[3].pricePerMonth, 2600);
    });
  });

  test('RentalRequest.buildId es determinista (evita solicitudes duplicadas)', () {
    expect(RentalRequest.buildId('u1', 'p9'), 'u1_p9');
    expect(RentalRequest.buildId('u1', 'p9'), RentalRequest.buildId('u1', 'p9'));
  });

  test('Report: valores por defecto', () {
    final r = Report.fromMap({
      'objetivoId': 'p1',
      'reportanteId': 'u2',
      'motivo': 'Información falsa',
    }, id: 'r1');
    expect(r.isOpen, isTrue);
    expect(r.type, TipoReporte.propiedad);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:renti/core/database/app_database.dart';

/// Pruebas del esquema SQLite con una base en memoria (sqflite_common_ffi).
void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppDatabase.version,
        onConfigure: AppDatabase.configurar,
        onCreate: AppDatabase.crearEsquema,
      ),
    );
  });

  tearDown(() => db.close());

  const ahora = '2026-05-10T12:00:00.000Z';

  Map<String, Object?> usuario(String uid, {String rol = 'arrendatario'}) => {
        'uid': uid,
        'nombre': 'Persona $uid',
        'email': '$uid@correo.com',
        'rol': rol,
        'creado_en': ahora,
        'actualizado_en': ahora,
      };

  Map<String, Object?> propiedad(String id, {String owner = 'dueno'}) => {
        'id': id,
        'propietario_id': owner,
        'titulo': 'Cuarto $id',
        'tipo': 'Habitación',
        'direccion': 'Calle Juárez 12',
        'precio': 2500,
        'creado_en': ahora,
        'actualizado_en': ahora,
      };

  Map<String, Object?> solicitud(String id,
          {String estado = 'PENDIENTE',
          String tenant = 'est1',
          String landlord = 'dueno'}) =>
      {
        'id': id,
        'propiedad_id': 'p1',
        'titulo_propiedad': 'Cuarto p1',
        'arrendatario_id': tenant,
        'arrendador_id': landlord,
        'meses': 3,
        'precio_mensual': 2500,
        'fecha_ingreso': ahora,
        'estado': estado,
        'creado_en': ahora,
        'actualizado_en': ahora,
      };

  test('crea las 7 tablas del modelo', () async {
    final filas = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
    final nombres = filas.map((f) => f['name']).toSet();
    expect(nombres, containsAll(AppDatabase.tablas));
  });

  test('CRUD de usuarios con parámetros', () async {
    await db.insert('usuarios', usuario('u1'));
    var f = await db.query('usuarios', where: 'uid = ?', whereArgs: ['u1']);
    expect(f.single['estado'], 'activo');

    await db.update('usuarios', {'nombre': 'Nuevo Nombre'},
        where: 'uid = ?', whereArgs: ['u1']);
    f = await db.query('usuarios', where: 'uid = ?', whereArgs: ['u1']);
    expect(f.single['nombre'], 'Nuevo Nombre');

    await db.delete('usuarios', where: 'uid = ?', whereArgs: ['u1']);
    expect(await db.query('usuarios'), isEmpty);
  });

  test('el correo es único', () async {
    await db.insert('usuarios', usuario('u1'));
    final repetido = usuario('u2')..['email'] = 'u1@correo.com';
    await expectLater(db.insert('usuarios', repetido), throwsA(isA<DatabaseException>()));
  });

  test('CHECK: rol, tipo y precio inválidos son rechazados', () async {
    await expectLater(db.insert('usuarios', usuario('u1', rol: 'superadmin')),
        throwsA(isA<DatabaseException>()));
    await expectLater(db.insert('propiedades', propiedad('p1')..['tipo'] = 'Castillo'),
        throwsA(isA<DatabaseException>()));
    await expectLater(db.insert('propiedades', propiedad('p1')..['precio'] = 0),
        throwsA(isA<DatabaseException>()));
  });

  test('una propiedad nueva queda pendiente y disponible', () async {
    await db.insert('propiedades', propiedad('p1'));
    final f = await db.query('propiedades');
    expect(f.single['moderacion'], 'pendiente');
    expect(f.single['estado'], 'disponible');
  });

  test('llave foránea: no hay imágenes sin propiedad y se borran en cascada',
      () async {
    final huerfana = {
      'id': 'i1',
      'propiedad_id': 'no-existe',
      'datos': 'abc',
      'creado_en': ahora,
    };
    await expectLater(db.insert('imagenes_propiedad', huerfana),
        throwsA(isA<DatabaseException>()));

    await db.insert('propiedades', propiedad('p1'));
    await db.insert('imagenes_propiedad', {...huerfana, 'propiedad_id': 'p1'});
    await db.delete('propiedades', where: 'id = ?', whereArgs: ['p1']);
    expect(await db.query('imagenes_propiedad'), isEmpty);
  });

  test('favoritos: clave primaria compuesta evita duplicados', () async {
    await db.insert('propiedades', propiedad('p1'));
    final fav = {'usuario_id': 'e1', 'propiedad_id': 'p1', 'creado_en': ahora};
    await db.insert('favoritos', fav);
    await expectLater(db.insert('favoritos', fav), throwsA(isA<DatabaseException>()));
  });

  test('solo una solicitud activa por estudiante y propiedad', () async {
    await db.insert('solicitudes_arrendamiento', solicitud('s1'));
    await expectLater(db.insert('solicitudes_arrendamiento', solicitud('s2')),
        throwsA(isA<DatabaseException>()));

    // Si la primera se cancela, ya se puede volver a solicitar.
    await db.update('solicitudes_arrendamiento', {'estado': 'CANCELADA'},
        where: 'id = ?', whereArgs: ['s1']);
    await db.insert('solicitudes_arrendamiento', solicitud('s2'));
    expect(await db.query('solicitudes_arrendamiento'), hasLength(2));
  });

  test('un usuario no puede solicitar su propia propiedad', () async {
    await expectLater(
      db.insert('solicitudes_arrendamiento',
          solicitud('s1', tenant: 'dueno', landlord: 'dueno')),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('arrendamiento: la fecha de fin no puede ser anterior al inicio', () async {
    final base = {
      'id': 'a1',
      'solicitud_id': 's1',
      'propiedad_id': 'p1',
      'titulo_propiedad': 'Cuarto',
      'arrendador_id': 'dueno',
      'arrendatario_id': 'est1',
      'fecha_inicio': '2026-06-01T00:00:00.000Z',
      'fecha_fin': '2026-05-01T00:00:00.000Z',
      'meses': 1,
      'precio_mensual': 2500,
      'creado_en': ahora,
      'actualizado_en': ahora,
    };
    await expectLater(db.insert('arrendamientos', base), throwsA(isA<DatabaseException>()));
    await db.insert('arrendamientos', {
      ...base,
      'fecha_fin': '2026-07-01T00:00:00.000Z',
    });
    expect((await db.query('arrendamientos')).single['estado'], 'activa');
  });

  test('transacción: si falla una operación no se guarda ninguna', () async {
    await expectLater(
      db.transaction((txn) async {
        await txn.insert('usuarios', usuario('u1'));
        await txn.insert('usuarios', usuario('u1')); // PK repetida
      }),
      throwsA(isA<DatabaseException>()),
    );
    expect(await db.query('usuarios'), isEmpty);
  });

  test('upsert actualiza si existe e inserta si no', () async {
    await AppDatabase.upsert(db, 'propiedades', propiedad('p1'));
    await AppDatabase.upsert(
        db, 'propiedades', propiedad('p1')..['precio'] = 3100);
    final f = await db.query('propiedades');
    expect(f, hasLength(1));
    expect(f.single['precio'], 3100);
  });
}

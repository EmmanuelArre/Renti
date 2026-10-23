import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base de datos SQLite local del dispositivo.
///
/// Papel dentro de la app: **caché y almacenamiento sin conexión**. La fuente
/// de verdad compartida entre teléfonos es Cloud Firestore; SQLite guarda una
/// copia de lo que la persona ha consultado para poder mostrarlo sin red y
/// para que las pantallas abran rápido. Se vacía al cerrar sesión.
///
/// Notas de diseño
///  * Las claves foráneas SOLO se declaran donde la fila hija siempre tiene a
///    su padre en la misma base (imagenes_propiedad y favoritos → propiedades).
///    Las solicitudes y arrendamientos guardan ids de usuarios/propiedades que
///    pueden no estar en caché, por eso allí son columnas simples con índice.
///  * Nunca se usa `ConflictAlgorithm.replace` en tablas padre: REPLACE borra
///    la fila y, con claves foráneas activas, borraría en cascada los hijos.
///    Se usa [upsert] (UPDATE y, si no existía, INSERT).
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _nombre = 'renti.db';
  static const version = 1;

  Database? _db;

  Future<Database> get database async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final ruta = p.join(await getDatabasesPath(), _nombre);
    return openDatabase(
      ruta,
      version: version,
      onConfigure: configurar,
      onCreate: crearEsquema,
    );
  }

  /// Sustituye la base (pruebas con base en memoria).
  void usarBase(Database db) => _db = db;

  Future<void> cerrar() async {
    await _db?.close();
    _db = null;
  }

  /// Borra todo el contenido local (se llama al cerrar sesión).
  Future<void> limpiar() async {
    final db = await database;
    await db.transaction((txn) async {
      for (final t in tablas.reversed) {
        await txn.delete(t);
      }
    });
  }

  // ------------------------------------------------------------------ esquema

  /// Orden de creación (padres primero).
  static const tablas = [
    'usuarios',
    'propiedades',
    'imagenes_propiedad',
    'favoritos',
    'solicitudes_arrendamiento',
    'arrendamientos',
    'notificaciones',
  ];

  static Future<void> configurar(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> crearEsquema(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE usuarios (
        uid            TEXT PRIMARY KEY,
        nombre         TEXT NOT NULL CHECK (length(trim(nombre)) >= 3),
        email          TEXT NOT NULL UNIQUE,
        rol            TEXT NOT NULL
                       CHECK (rol IN ('arrendador','arrendatario','administrador')),
        universidad    TEXT NOT NULL DEFAULT '',
        telefono       TEXT NOT NULL DEFAULT '',
        estado         TEXT NOT NULL DEFAULT 'activo'
                       CHECK (estado IN ('activo','suspendido')),
        proveedor      TEXT NOT NULL DEFAULT 'password',
        creado_en      TEXT NOT NULL,
        actualizado_en TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE propiedades (
        id                 TEXT PRIMARY KEY,
        propietario_id     TEXT NOT NULL,
        propietario_nombre TEXT NOT NULL DEFAULT '',
        titulo             TEXT NOT NULL CHECK (length(trim(titulo)) >= 3),
        tipo               TEXT NOT NULL
                           CHECK (tipo IN ('Habitación','Departamento','Casa','Compartido')),
        direccion          TEXT NOT NULL,
        referencia         TEXT NOT NULL DEFAULT '',
        precio             INTEGER NOT NULL CHECK (precio > 0),
        descripcion        TEXT NOT NULL DEFAULT '',
        habitaciones       INTEGER NOT NULL DEFAULT 1 CHECK (habitaciones >= 0),
        banos              INTEGER NOT NULL DEFAULT 1 CHECK (banos >= 0),
        compartido         INTEGER NOT NULL DEFAULT 0 CHECK (compartido IN (0,1)),
        servicios          TEXT NOT NULL DEFAULT '[]',
        estado             TEXT NOT NULL DEFAULT 'disponible'
                           CHECK (estado IN ('disponible','rentado')),
        moderacion         TEXT NOT NULL DEFAULT 'pendiente'
                           CHECK (moderacion IN ('pendiente','aprobada','rechazada','desactivada')),
        portada            TEXT NOT NULL DEFAULT '',
        rating             REAL,
        resenas            INTEGER NOT NULL DEFAULT 0,
        creado_en          TEXT NOT NULL,
        actualizado_en     TEXT NOT NULL
      )
    ''');
    batch.execute(
        'CREATE INDEX ix_propiedades_propietario ON propiedades(propietario_id)');
    batch.execute(
        'CREATE INDEX ix_propiedades_publica ON propiedades(moderacion, estado)');

    batch.execute('''
      CREATE TABLE imagenes_propiedad (
        id           TEXT PRIMARY KEY,
        propiedad_id TEXT NOT NULL
                     REFERENCES propiedades(id) ON DELETE CASCADE,
        orden        INTEGER NOT NULL DEFAULT 0 CHECK (orden >= 0),
        datos        TEXT NOT NULL CHECK (length(datos) > 0),
        creado_en    TEXT NOT NULL
      )
    ''');
    batch.execute(
        'CREATE INDEX ix_imagenes_propiedad ON imagenes_propiedad(propiedad_id, orden)');

    batch.execute('''
      CREATE TABLE favoritos (
        usuario_id   TEXT NOT NULL,
        propiedad_id TEXT NOT NULL
                     REFERENCES propiedades(id) ON DELETE CASCADE,
        creado_en    TEXT NOT NULL,
        PRIMARY KEY (usuario_id, propiedad_id)
      )
    ''');

    batch.execute('''
      CREATE TABLE solicitudes_arrendamiento (
        id                  TEXT PRIMARY KEY,
        propiedad_id        TEXT NOT NULL,
        titulo_propiedad    TEXT NOT NULL,
        arrendatario_id     TEXT NOT NULL,
        arrendatario_nombre TEXT NOT NULL DEFAULT '',
        arrendador_id       TEXT NOT NULL,
        meses               INTEGER NOT NULL CHECK (meses >= 0),
        precio_mensual      INTEGER NOT NULL CHECK (precio_mensual > 0),
        fecha_ingreso       TEXT NOT NULL,
        mensaje             TEXT NOT NULL DEFAULT '',
        metodo_pago         TEXT NOT NULL DEFAULT 'Efectivo',
        estado              TEXT NOT NULL DEFAULT 'PENDIENTE'
                            CHECK (estado IN ('PENDIENTE','ACEPTADA','RECHAZADA','CANCELADA')),
        creado_en           TEXT NOT NULL,
        actualizado_en      TEXT NOT NULL,
        CHECK (arrendatario_id <> arrendador_id)
      )
    ''');
    batch.execute(
        'CREATE INDEX ix_solicitudes_arrendatario ON solicitudes_arrendamiento(arrendatario_id)');
    batch.execute(
        'CREATE INDEX ix_solicitudes_arrendador ON solicitudes_arrendamiento(arrendador_id)');
    // Una sola solicitud activa por estudiante y propiedad.
    batch.execute('''
      CREATE UNIQUE INDEX ux_solicitud_activa
      ON solicitudes_arrendamiento(propiedad_id, arrendatario_id)
      WHERE estado IN ('PENDIENTE','ACEPTADA')
    ''');

    batch.execute('''
      CREATE TABLE arrendamientos (
        id                  TEXT PRIMARY KEY,
        solicitud_id        TEXT NOT NULL,
        propiedad_id        TEXT NOT NULL,
        titulo_propiedad    TEXT NOT NULL,
        direccion           TEXT NOT NULL DEFAULT '',
        arrendador_id       TEXT NOT NULL,
        arrendador_nombre   TEXT NOT NULL DEFAULT '',
        arrendatario_id     TEXT NOT NULL,
        arrendatario_nombre TEXT NOT NULL DEFAULT '',
        fecha_inicio        TEXT NOT NULL,
        fecha_fin           TEXT NOT NULL,
        meses               INTEGER NOT NULL CHECK (meses >= 0),
        precio_mensual      INTEGER NOT NULL CHECK (precio_mensual > 0),
        estado              TEXT NOT NULL DEFAULT 'activa'
                            CHECK (estado IN ('activa','finalizada')),
        creado_en           TEXT NOT NULL,
        actualizado_en      TEXT NOT NULL,
        CHECK (fecha_fin >= fecha_inicio)
      )
    ''');
    batch.execute(
        'CREATE INDEX ix_arrendamientos_arrendatario ON arrendamientos(arrendatario_id)');
    batch.execute(
        'CREATE INDEX ix_arrendamientos_arrendador ON arrendamientos(arrendador_id)');

    batch.execute('''
      CREATE TABLE notificaciones (
        id         TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        origen_id  TEXT NOT NULL DEFAULT '',
        tipo       TEXT NOT NULL DEFAULT '',
        titulo     TEXT NOT NULL,
        mensaje    TEXT NOT NULL DEFAULT '',
        leida      INTEGER NOT NULL DEFAULT 0 CHECK (leida IN (0,1)),
        creado_en  TEXT NOT NULL
      )
    ''');
    batch.execute(
        'CREATE INDEX ix_notificaciones_usuario ON notificaciones(usuario_id, creado_en)');

    await batch.commit(noResult: true);
  }

  // ----------------------------------------------------------------- helpers

  /// UPDATE y, si la fila no existía, INSERT. No dispara borrados en cascada.
  static Future<void> upsert(
    DatabaseExecutor db,
    String tabla,
    Map<String, Object?> valores, {
    String clave = 'id',
  }) async {
    final n = await db.update(
      tabla,
      valores,
      where: '$clave = ?',
      whereArgs: [valores[clave]],
    );
    if (n == 0) await db.insert(tabla, valores);
  }
}

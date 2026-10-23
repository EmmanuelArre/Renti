import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/database/app_database.dart';
import 'package:renti/core/services/auth_service.dart';
import 'package:renti/core/services/image_service.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/models/app_notification.dart';
import 'package:renti/models/app_user.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/models/rental.dart';
import 'package:renti/models/report.dart';
import 'package:renti/repositories/favorite_repository.dart';
import 'package:renti/repositories/notification_repository.dart';
import 'package:renti/repositories/property_repository.dart';
import 'package:renti/repositories/report_repository.dart';
import 'package:renti/repositories/request_repository.dart';
import 'package:renti/repositories/stats_repository.dart';
import 'package:renti/repositories/user_repository.dart';

// Los formatos viven en core/utils, pero casi todas las pantallas ya
// importan este archivo, así que se reexportan aquí.
export 'package:renti/core/utils/formatters.dart';

/// Filtros de búsqueda compartidos entre Buscar, Filtros y Resultados.
class SearchFilters {
  static const precioMin = 500.0;
  static const precioMax = 10000.0;

  String place = '';
  String? university;
  DateTime? entryDate;
  int months = 3;
  RangeValues price = const RangeValues(precioMin, precioMax);
  Set<String> types = {};
  Set<String> services = {};

  void clear() {
    place = '';
    price = const RangeValues(precioMin, precioMax);
    types = {};
    services = {};
  }

  /// Aplica búsqueda por texto + precio + tipo + servicios.
  List<Listing> aplicar(Iterable<Listing> origen) {
    final q = place.trim().toLowerCase();
    return origen.where((l) {
      if (l.price < price.start || l.price > price.end) return false;
      if (types.isNotEmpty && !types.contains(l.type)) return false;
      if (services.isNotEmpty && !services.every(l.services.contains)) {
        return false;
      }
      if (q.isNotEmpty &&
          !('${l.title} ${l.address} ${l.distance}'.toLowerCase().contains(q))) {
        return false;
      }
      return true;
    }).toList();
  }
}

/// A dónde debe ir la app después de identificar a la persona.
enum Destino { bienvenida, verificarCorreo, elegirRol, inicio, suspendida }

/// Estado global (ChangeNotifier, sin paquetes externos).
///
/// Mantiene la sesión, los datos que las pantallas muestran y delega la
/// persistencia en los repositorios (Firestore + SQLite). Cada operación que
/// modifica datos devuelve `null` si salió bien o el mensaje de error listo
/// para mostrar.
class AppState extends ChangeNotifier {
  // ---------------------------------------------------------------- sesión
  AppUser? user;
  ThemeMode themeMode = ThemeMode.light;

  /// Pestaña activa del menú inferior de cada rol.
  int tab = 0;

  // Datos de una cuenta nueva que aún no eligió rol (Google, primera vez).
  User? _pendienteFirebase;
  String get nombrePendiente => _pendienteFirebase?.displayName ?? '';

  bool get hasSession => user != null;
  bool get isLandlord => user?.esArrendador ?? false;
  bool get isTenant => user?.esArrendatario ?? false;
  bool get isAdmin => user?.esAdmin ?? false;
  String get userName => user?.nombre ?? '';
  String get userEmail => user?.email ?? '';
  String get university => user?.universidad ?? '';
  String get roleLabel => Roles.etiqueta(user?.rol ?? Roles.arrendatario);

  // ----------------------------------------------------------------- datos
  final SearchFilters filters = SearchFilters();
  List<Listing> listings = []; // públicas (estudiante)
  List<Listing> myListings = []; // del arrendador
  List<Listing> favoriteListings = [];
  final Set<String> favorites = {};
  List<RentalRequest> requests = []; // enviadas (estudiante) o recibidas
  List<Rental> rentals = [];
  List<AppNotification> notifications = [];

  // Administrador
  List<AppUser> adminUsers = [];
  List<Listing> adminListings = [];
  List<Report> reports = [];
  List<RentalRequest> adminRequests = [];
  List<Rental> adminRentals = [];
  Estadisticas stats = const Estadisticas();

  bool loading = false;
  bool offline = false;
  String? loadError;

  final _users = UserRepository.instance;
  final _props = PropertyRepository.instance;
  final _favs = FavoriteRepository.instance;
  final _reqs = RequestRepository.instance;
  final _notifs = NotificationRepository.instance;
  final _reportsRepo = ReportRepository.instance;

  // ------------------------------------------------------------ preferencias

  Future<void> cargarPreferencias() async {
    try {
      final p = await SharedPreferences.getInstance();
      themeMode = p.getString('tema') == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      themeMode = ThemeMode.light;
    }
  }

  void setTheme(ThemeMode m) {
    themeMode = m;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setString('tema', m == ThemeMode.dark ? 'dark' : 'light'))
        .catchError((_) => false);
  }

  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  // ----------------------------------------------------------- inicio sesión

  /// Averigua quién es la persona autenticada y a dónde debe ir.
  ///
  /// El rol se lee SIEMPRE del servidor (Firestore). El administrador se
  /// reconoce por la existencia de `admins/{uid}`, que solo se crea desde la
  /// consola de Firebase; ningún dato local puede concederlo.
  Future<Destino> iniciarSesionDesde(User fb) async {
    AppUser? perfil;
    var admin = false;
    try {
      admin = await _users.esAdministrador(fb.uid);
      perfil = await _users.obtener(fb.uid);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') rethrow;
      // Sin red: se usa el último perfil guardado en SQLite.
      perfil = await _users.obtenerLocal(fb.uid);
      if (perfil == null) rethrow;
      admin = perfil.esAdmin;
      offline = true;
    }

    if (admin) {
      perfil = (perfil ??
              AppUser(
                uid: fb.uid,
                nombre: (fb.displayName ?? '').trim().length >= 3
                    ? fb.displayName!.trim()
                    : 'Administrador',
                email: fb.email ?? '',
                rol: Roles.administrador,
                proveedor: AuthService.instance.proveedorDe(fb),
              ))
          .copyWith(rol: Roles.administrador);
    }

    if (perfil == null) {
      _pendienteFirebase = fb;
      return Destino.elegirRol;
    }
    if (!perfil.activo) {
      await cerrarSesion();
      return Destino.suspendida;
    }

    user = perfil;
    await _users.guardarLocal(perfil);
    tab = 0;
    notifyListeners();

    if (!admin &&
        AuthService.instance.usaContrasena(fb) &&
        !fb.emailVerified) {
      return Destino.verificarCorreo;
    }
    unawaited(cargarTodo());
    return Destino.inicio;
  }

  /// Crea el perfil de una cuenta recién registrada (correo o Google).
  Future<Destino> crearPerfil({
    required User fb,
    required String nombre,
    required String rol,
    required String universidad,
  }) async {
    final errores = [
      Validators.nombreCompleto(nombre),
      Validators.rol(rol),
    ].whereType<String>();
    if (errores.isNotEmpty) throw RentiException(errores.first);

    final perfil = AppUser(
      uid: fb.uid,
      nombre: Validators.normalizarEspacios(nombre),
      email: (fb.email ?? '').toLowerCase(),
      rol: rol,
      universidad: universidad,
      proveedor: AuthService.instance.proveedorDe(fb),
    );
    await _users.crear(perfil);
    _pendienteFirebase = null;
    return iniciarSesionDesde(fb);
  }

  Future<void> cerrarSesion() async {
    await AuthService.instance.cerrarSesion();
    await cacheSegura0(() => AppDatabase.instance.limpiar());
    _resetear();
    notifyListeners();
  }

  void _resetear() {
    user = null;
    _pendienteFirebase = null;
    tab = 0;
    listings = [];
    myListings = [];
    favoriteListings = [];
    favorites.clear();
    requests = [];
    rentals = [];
    notifications = [];
    adminUsers = [];
    adminListings = [];
    reports = [];
    adminRequests = [];
    adminRentals = [];
    stats = const Estadisticas();
    filters.clear();
    filters.university = null;
    filters.entryDate = null;
    loadError = null;
    offline = false;
  }

  // ------------------------------------------------------------ carga datos

  /// Descarga (o lee de la caché) todo lo que necesita el rol actual.
  Future<void> cargarTodo() async {
    final u = user;
    if (u == null) return;
    loading = true;
    loadError = null;
    notifyListeners();
    var sinRed = false;
    try {
      if (u.esAdmin) {
        await _cargarAdmin();
      } else {
        if (u.esArrendatario) {
          final pub = await _props.publicas(u.uid);
          listings = pub.datos;
          sinRed = sinRed || pub.desdeCache;
          final fav = await _favs.cargar(u.uid, listings);
          favoriteListings = fav.datos;
          favorites
            ..clear()
            ..addAll(fav.datos.map((l) => l.id));
          final sol = await _reqs.delArrendatario(u.uid);
          requests = sol.datos;
          final arr = await _reqs.arrendamientosDe(u.uid, comoArrendador: false);
          rentals = arr.datos;
          sinRed = sinRed || sol.desdeCache || arr.desdeCache;
        } else if (u.esArrendador) {
          final mias = await _props.delPropietario(u.uid);
          myListings = mias.datos;
          final sol = await _reqs.delArrendador(u.uid);
          requests = sol.datos;
          final arr = await _reqs.arrendamientosDe(u.uid, comoArrendador: true);
          rentals = arr.datos;
          sinRed = mias.desdeCache || sol.desdeCache || arr.desdeCache;
        }
        final n = await _notifs.cargar(u.uid);
        notifications = n.datos;
      }
      offline = sinRed;
    } catch (e) {
      loadError = _mensaje(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarAdmin() async {
    adminUsers = await _users.listar();
    adminListings = await _props.todas();
    reports = await _reportsRepo.todos();
    adminRequests = await _reqs.todasLasSolicitudes();
    adminRentals = await _reqs.todosLosArrendamientos();
    stats = await StatsRepository.instance.cargar();
  }

  // -------------------------------------------------------------- favoritos

  bool isFavorite(String id) => favorites.contains(id);

  Future<String?> toggleFavorite(Listing l) async {
    final u = user;
    if (u == null || !u.esArrendatario) {
      return 'Solo los estudiantes pueden guardar favoritos.';
    }
    final eraFavorito = favorites.contains(l.id);
    if (eraFavorito) {
      favorites.remove(l.id);
      favoriteListings = favoriteListings.where((x) => x.id != l.id).toList();
    } else {
      favorites.add(l.id);
      favoriteListings = [l, ...favoriteListings];
    }
    notifyListeners();
    final error = await _ejecutar(() async {
      if (eraFavorito) {
        await _favs.quitar(u.uid, l.id);
      } else {
        await _favs.agregar(u.uid, l);
      }
    });
    if (error != null) {
      // Revierte el cambio optimista.
      if (eraFavorito) {
        favorites.add(l.id);
        favoriteListings = [l, ...favoriteListings];
      } else {
        favorites.remove(l.id);
        favoriteListings = favoriteListings.where((x) => x.id != l.id).toList();
      }
      notifyListeners();
    }
    return error;
  }

  // ------------------------------------------------------------ propiedades

  Future<String?> crearPropiedad(
      DatosPropiedad datos, List<FotoPropiedad> fotos) {
    return _ejecutar(() async {
      final l = await _props.crear(
        propietario: _requerirUsuario(),
        datos: datos,
        fotos: fotos,
      );
      myListings = [l, ...myListings];
      notifyListeners();
    });
  }

  Future<String?> editarPropiedad(
      Listing original, DatosPropiedad datos, List<FotoPropiedad>? fotos) {
    return _ejecutar(() async {
      _requerirPropietario(original);
      final l = await _props.actualizar(
          original: original, datos: datos, fotos: fotos);
      myListings = myListings.map((x) => x.id == l.id ? l : x).toList();
      notifyListeners();
    });
  }

  Future<String?> cambiarDisponibilidad(Listing l, ListingStatus s) {
    return _ejecutar(() async {
      _requerirPropietario(l);
      final nuevo = await _props.cambiarDisponibilidad(l, s);
      myListings = myListings.map((x) => x.id == l.id ? nuevo : x).toList();
      notifyListeners();
    });
  }

  Future<String?> eliminarPropiedad(Listing l) {
    return _ejecutar(() async {
      _requerirPropietario(l);
      await _props.eliminar(l);
      myListings = myListings.where((x) => x.id != l.id).toList();
      notifyListeners();
    });
  }

  // ------------------------------------------------------------ solicitudes

  Future<({RentalRequest? request, String? error})> enviarSolicitud({
    required Listing propiedad,
    required DurationOption opcion,
    required DateTime fechaIngreso,
    required String mensaje,
    required String metodoPago,
  }) async {
    RentalRequest? creada;
    final error = await _ejecutar(() async {
      creada = await _reqs.enviar(
        arrendatario: user,
        propiedad: propiedad,
        opcion: opcion,
        fechaIngreso: fechaIngreso,
        mensaje: mensaje,
        metodoPago: metodoPago,
      );
      requests = [creada!, ...requests.where((r) => r.id != creada!.id)];
      notifyListeners();
    });
    if (creada != null) {
      unawaited(_notifs.avisar(
        paraUid: creada!.landlordId,
        deUid: user!.uid,
        tipo: 'solicitud',
        titulo: 'Nueva solicitud de renta',
        mensaje: '${user!.nombre} quiere rentar "${propiedad.title}".',
      ));
    }
    return (request: creada, error: error);
  }

  Future<String?> responderSolicitud(RentalRequest r, bool aceptar) async {
    final error = await _ejecutar(() async {
      await _reqs.responder(arrendador: user, solicitud: r, aceptar: aceptar);
    });
    if (error != null) return error;
    unawaited(_notifs.avisar(
      paraUid: r.tenantId,
      deUid: user!.uid,
      tipo: 'solicitud',
      titulo: aceptar ? '¡Solicitud aceptada!' : 'Solicitud rechazada',
      mensaje: aceptar
          ? '${user!.nombre} aceptó tu solicitud para "${r.listingTitle}".'
          : '${user!.nombre} no pudo aceptar tu solicitud para "${r.listingTitle}".',
    ));
    await _recargarArrendador();
    return null;
  }

  Future<String?> cancelarSolicitud(RentalRequest r) {
    return _ejecutar(() async {
      await _reqs.cancelar(user, r);
      requests = requests
          .map((x) => x.id == r.id ? x.copyWith(status: EstadoSolicitud.cancelada) : x)
          .toList();
      notifyListeners();
    });
  }

  Future<String?> finalizarArrendamiento(Rental r) {
    return _ejecutar(() async {
      final nuevo = await _reqs.finalizar(user, r);
      rentals = rentals.map((x) => x.id == r.id ? nuevo : x).toList();
      notifyListeners();
    }).then((error) async {
      if (error == null) {
        unawaited(_notifs.avisar(
          paraUid: r.tenantId,
          deUid: user!.uid,
          tipo: 'arrendamiento',
          titulo: 'Arrendamiento finalizado',
          mensaje: 'Tu renta de "${r.listingTitle}" fue marcada como finalizada.',
        ));
        await _recargarArrendador();
      }
      return error;
    });
  }

  Future<void> _recargarArrendador() async {
    final u = user;
    if (u == null || !u.esArrendador) return;
    try {
      myListings = (await _props.delPropietario(u.uid)).datos;
      requests = (await _reqs.delArrendador(u.uid)).datos;
      rentals = (await _reqs.arrendamientosDe(u.uid, comoArrendador: true)).datos;
    } catch (e) {
      loadError = _mensaje(e);
    }
    notifyListeners();
  }

  int get pendingRequests => requests.where((r) => r.isPending).length;

  // ---------------------------------------------------------------- perfil

  Future<String?> actualizarPerfil({
    required String nombre,
    required String telefono,
    required String universidad,
  }) {
    return _ejecutar(() async {
      final actual = _requerirUsuario();
      user = await _users.actualizarPerfil(
        actual,
        nombre: nombre,
        telefono: telefono,
        universidad: universidad,
      );
      notifyListeners();
    });
  }

  // ----------------------------------------------------------- notificaciones

  int get unreadNotifications => notifications.where((n) => !n.read).length;

  Future<void> marcarNotificacionesLeidas() async {
    final pendientes = notifications.where((n) => !n.read).toList();
    if (pendientes.isEmpty) return;
    notifications = notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
    await _ejecutar(() => _notifs.marcarLeidas(pendientes));
  }

  // -------------------------------------------------------------- reportes

  Future<String?> enviarReporte({
    required String tipo,
    required String objetivoId,
    required String objetivoNombre,
    required String motivo,
    required String detalle,
  }) {
    return _ejecutar(() async {
      await _reportsRepo.crear(
        autor: user,
        tipo: tipo,
        objetivoId: objetivoId,
        objetivoNombre: objetivoNombre,
        motivo: motivo,
        detalle: detalle,
      );
    });
  }

  // --------------------------------------------------------- administrador

  Future<void> recargarAdmin() async {
    if (!isAdmin) return;
    loading = true;
    notifyListeners();
    try {
      await _cargarAdmin();
      loadError = null;
    } catch (e) {
      loadError = _mensaje(e);
    }
    loading = false;
    notifyListeners();
  }

  Future<String?> moderarPropiedad(Listing l, String moderacion,
      {String motivo = ''}) async {
    final error = await _ejecutar(() async {
      _requerirAdmin();
      await _props.moderar(l.id, moderacion, motivo: motivo);
      adminListings = adminListings
          .map((x) => x.id == l.id ? x.copyWith(moderation: moderacion) : x)
          .toList();
      notifyListeners();
    });
    if (error == null) {
      unawaited(_notifs.avisar(
        paraUid: l.ownerId,
        deUid: user!.uid,
        tipo: 'moderacion',
        titulo: 'Tu publicación fue ${Moderacion.etiqueta(moderacion).toLowerCase()}',
        mensaje: motivo.isEmpty
            ? '"${l.title}" cambió a ${Moderacion.etiqueta(moderacion).toLowerCase()}.'
            : '"${l.title}": $motivo',
      ));
      unawaited(_refrescarStats());
    }
    return error;
  }

  Future<String?> cambiarEstadoUsuario(AppUser u, String estado) async {
    final error = await _ejecutar(() async {
      _requerirAdmin();
      if (u.uid == user!.uid) {
        throw const RentiException('No puedes suspender tu propia cuenta.');
      }
      await _users.cambiarEstado(u.uid, estado);
      adminUsers = adminUsers
          .map((x) => x.uid == u.uid ? x.copyWith(estado: estado) : x)
          .toList();
      notifyListeners();
    });
    return error;
  }

  Future<String?> resolverReporte(Report r, String estado, String nota) {
    return _ejecutar(() async {
      _requerirAdmin();
      await _reportsRepo.resolver(r.id, estado, nota);
      reports = await _reportsRepo.todos();
      notifyListeners();
      unawaited(_refrescarStats());
    });
  }

  Future<void> _refrescarStats() async {
    try {
      stats = await StatsRepository.instance.cargar();
      notifyListeners();
    } catch (_) {}
  }

  // ---------------------------------------------------------------- helpers

  AppUser _requerirUsuario() {
    final u = user;
    if (u == null) throw const RentiException('Inicia sesión para continuar.');
    return u;
  }

  void _requerirPropietario(Listing l) {
    final u = _requerirUsuario();
    if (!u.esArrendador || l.ownerId != u.uid) {
      throw const RentiException('Solo puedes modificar tus propias propiedades.');
    }
  }

  void _requerirAdmin() {
    if (!(user?.esAdmin ?? false)) {
      throw const RentiException('Acción reservada para administradores.');
    }
  }

  Future<String?> _ejecutar(Future<void> Function() accion) async {
    try {
      await accion();
      return null;
    } catch (e) {
      return _mensaje(e);
    }
  }

  static String _mensaje(Object e) {
    if (e is RentiException) return e.message;
    if (e is FirebaseException && e.plugin == 'cloud_firestore') {
      switch (e.code) {
        case 'permission-denied':
          return 'No tienes permiso para realizar esta acción.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'Sin conexión con el servidor. Inténtalo de nuevo.';
        case 'not-found':
          return 'El elemento ya no existe.';
        case 'already-exists':
          return 'Ese registro ya existe.';
        default:
          return 'Error del servidor (${e.code}).';
      }
    }
    return AuthService.mensajeDe(e);
  }

  /// Mensaje de error legible para cualquier excepción (usado por pantallas).
  static String mensajeDeError(Object e) => _mensaje(e);
}

/// Ejecuta una acción de caché ignorando cualquier error.
Future<void> cacheSegura0(Future<void> Function() f) async {
  try {
    await f();
  } catch (_) {}
}

final appState = AppState();

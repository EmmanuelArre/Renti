import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Envoltura de Firebase Authentication (correo/contraseña y Google).
///
/// Firebase se encarga de guardar y verificar las credenciales; la app nunca
/// almacena contraseñas. La sesión se conserva automáticamente en el
/// dispositivo hasta que se llama a [cerrarSesion].
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get usuarioActual => _auth.currentUser;
  Stream<User?> get cambios => _auth.authStateChanges();

  /// `true` si la cuenta entró con correo/contraseña (requiere verificación).
  bool usaContrasena(User u) =>
      u.providerData.any((p) => p.providerId == 'password');

  String proveedorDe(User u) => usaContrasena(u) ? 'password' : 'google.com';

  // ---------------------------------------------------------- correo y clave

  Future<User> registrarConCorreo({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: correo,
      password: contrasena,
    );
    final user = cred.user!;
    await user.updateDisplayName(nombre);
    await user.sendEmailVerification();
    return user;
  }

  Future<User> iniciarConCorreo({
    required String correo,
    required String contrasena,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: correo,
      password: contrasena,
    );
    return cred.user!;
  }

  Future<void> recuperarContrasena(String correo) =>
      _auth.sendPasswordResetEmail(email: correo);

  Future<void> reenviarVerificacion() async {
    final u = _auth.currentUser;
    if (u != null && !u.emailVerified) await u.sendEmailVerification();
  }

  /// Vuelve a leer el usuario desde el servidor y dice si ya verificó.
  Future<bool> verificarCorreoActualizado() async {
    final u = _auth.currentUser;
    if (u == null) return false;
    await u.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ------------------------------------------------------------------ Google

  /// Devuelve `null` si la persona cancela la ventana de Google.
  ///
  /// Usa la API de `google_sign_in` 6.x. Si migras a la 7.x, la llamada pasa
  /// a ser:
  ///   await GoogleSignIn.instance.initialize();
  ///   final cuenta = await GoogleSignIn.instance.authenticate();
  ///   final credencial = GoogleAuthProvider.credential(
  ///       idToken: cuenta.authentication.idToken);
  Future<User?> iniciarConGoogle() async {
    final google = GoogleSignIn(scopes: const ['email']);
    final cuenta = await google.signIn();
    if (cuenta == null) return null;
    final auth = await cuenta.authentication;
    final credencial = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    final cred = await _auth.signInWithCredential(credencial);
    return cred.user;
  }

  // ------------------------------------------------------------------ cierre

  Future<void> cerrarSesion() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Si Google no estaba en uso, no hay nada que cerrar.
    }
    await _auth.signOut();
  }

  // ----------------------------------------------------------------- errores

  /// Traduce errores de Firebase a mensajes claros en español.
  static String mensajeDe(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'El correo no tiene un formato válido.';
        case 'user-disabled':
          return 'Esta cuenta fue deshabilitada. Contacta a soporte.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Correo o contraseña incorrectos.';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con ese correo. Inicia sesión.';
        case 'weak-password':
          return 'La contraseña es demasiado débil.';
        case 'too-many-requests':
          return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
        case 'network-request-failed':
          return 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
        case 'account-exists-with-different-credential':
          return 'Ese correo ya está registrado con otro método. '
              'Inicia sesión con tu contraseña.';
        case 'requires-recent-login':
          return 'Por seguridad, vuelve a iniciar sesión.';
        case 'operation-not-allowed':
          return 'Este método de acceso no está habilitado en Firebase.';
        default:
          return 'No se pudo completar la autenticación (${error.code}).';
      }
    }
    final texto = error.toString();
    if (texto.contains('ApiException: 10') ||
        texto.contains('sign_in_failed')) {
      return 'Google Sign-In no está configurado: revisa el SHA-1 y el '
          'google-services.json (ver README).';
    }
    if (texto.contains('network_error')) {
      return 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
}

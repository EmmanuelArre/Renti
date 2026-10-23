import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/features/administrador/admin_shell.dart';
import 'package:renti/features/arrendador/landlord_shell.dart';
import 'package:renti/features/arrendatario/tenant_shell.dart';
import 'package:renti/features/auth/forgot_password_screen.dart';
import 'package:renti/features/auth/login_screen.dart';
import 'package:renti/features/auth/register_screen.dart';
import 'package:renti/features/auth/select_role_screen.dart';
import 'package:renti/features/auth/splash_screen.dart';
import 'package:renti/features/auth/verify_email_screen.dart';
import 'package:renti/features/auth/welcome_screen.dart';

/// Rutas con nombre de la aplicación y su protección por rol.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const welcome = '/bienvenida';
  static const login = '/login';
  static const register = '/registro';
  static const forgotPassword = '/recuperar-contrasena';
  static const verifyEmail = '/verificar-correo';
  static const selectRole = '/elegir-rol';
  static const tenantHome = '/estudiante';
  static const landlordHome = '/arrendador';
  static const adminHome = '/administrador';

  /// Pantalla de inicio que corresponde al rol de la sesión actual.
  static String homeForCurrentUser() {
    if (appState.isAdmin) return adminHome;
    if (appState.isLandlord) return landlordHome;
    return tenantHome;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fade(settings, const SplashScreen());
      case welcome:
        return _fade(settings, const WelcomeScreen());
      case login:
        return _slide(settings, const LoginScreen());
      case register:
        return _slide(settings, const RegisterScreen());
      case forgotPassword:
        return _slide(settings, const ForgotPasswordScreen());
      case verifyEmail:
        return _fade(settings, const VerifyEmailScreen());
      case selectRole:
        return _fade(settings, const SelectRoleScreen());
      case tenantHome:
        return _fade(
          settings,
          const RoleGuard(role: Role.tenant, child: TenantShell()),
        );
      case landlordHome:
        return _fade(
          settings,
          const RoleGuard(role: Role.landlord, child: LandlordShell()),
        );
      case adminHome:
        return _fade(
          settings,
          const RoleGuard(role: Role.admin, child: AdminShell()),
        );
    }
    return _fade(settings, const WelcomeScreen());
  }

  /// Lleva a la pantalla adecuada según lo que resolvió el inicio de sesión.
  static void goTo(BuildContext context, Destino destino) {
    final nav = Navigator.of(context);
    switch (destino) {
      case Destino.bienvenida:
        nav.pushNamedAndRemoveUntil(welcome, (_) => false);
      case Destino.suspendida:
        nav.pushNamedAndRemoveUntil(welcome, (_) => false,
            arguments: 'suspendida');
      case Destino.verificarCorreo:
        nav.pushNamedAndRemoveUntil(verifyEmail, (_) => false);
      case Destino.elegirRol:
        nav.pushNamedAndRemoveUntil(selectRole, (_) => false);
      case Destino.inicio:
        nav.pushNamedAndRemoveUntil(homeForCurrentUser(), (_) => false);
    }
  }

  /// Cierra la sesión y vuelve a la bienvenida.
  static Future<void> cerrarSesion(BuildContext context) async {
    final nav = Navigator.of(context);
    await appState.cerrarSesion();
    nav.pushNamedAndRemoveUntil(welcome, (_) => false);
  }

  static PageRoute<dynamic> _fade(RouteSettings s, Widget page) =>
      PageRouteBuilder(
        settings: s,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      );

  static PageRoute<dynamic> _slide(RouteSettings s, Widget page) =>
      MaterialPageRoute(settings: s, builder: (_) => page);
}

enum Role { tenant, landlord, admin }

/// Solo muestra [child] si la sesión actual tiene el rol pedido. Es una
/// segunda barrera de la interfaz; la protección real está en las reglas de
/// Firestore y en las comprobaciones de los repositorios.
class RoleGuard extends StatelessWidget {
  final Role role;
  final Widget child;
  const RoleGuard({super.key, required this.role, required this.child});

  bool get _permitido {
    switch (role) {
      case Role.tenant:
        return appState.isTenant;
      case Role.landlord:
        return appState.isLandlord;
      case Role.admin:
        return appState.isAdmin;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_permitido) return child;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(RentiTheme.pad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 64, color: RentiColors.orange),
                const SizedBox(height: 20),
                Text(
                  'No tienes acceso a esta sección',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.ink,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: appState.hasSession ? 'Ir a mi inicio' : 'Iniciar sesión',
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    appState.hasSession
                        ? AppRoutes.homeForCurrentUser()
                        : AppRoutes.welcome,
                    (_) => false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

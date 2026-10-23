import 'dart:async';

import 'package:flutter/material.dart';

import 'package:renti/app/routes.dart';
import 'package:renti/core/services/auth_service.dart';
import 'package:renti/core/state/app_state.dart';

import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/renti_logo.dart';

/// 01 · Splash
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _dot = 0;
  Timer? _dots;

  @override
  void initState() {
    super.initState();
    _dots = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (mounted) setState(() => _dot = (_dot + 1) % 3);
    });
    _arrancar();
  }

  /// Espera la animación y, en paralelo, restaura la sesión guardada.
  Future<void> _arrancar() async {
    final espera = Future<void>.delayed(const Duration(milliseconds: 1800));
    var destino = Destino.bienvenida;
    try {
      final fb = AuthService.instance.usuarioActual;
      if (fb != null) {
        try {
          await fb.reload(); // por si verificó su correo en otro dispositivo
        } catch (_) {
          // Sin red: se sigue con los datos guardados.
        }
        destino = await appState.iniciarSesionDesde(
            AuthService.instance.usuarioActual ?? fb);
      }
    } catch (_) {
      destino = Destino.bienvenida;
    }
    await espera;
    if (!mounted) return;
    AppRoutes.goTo(context, destino);
  }

  @override
  void dispose() {
    _dots?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RentiColors.blue,
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const RentiLogo(size: 92),
            const SizedBox(height: 22),
            const Text(
              'Renti',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu espacio. Tu etapa.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 90),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: i == _dot ? 10 : 8,
                    height: i == _dot ? 10 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _dot
                          ? RentiColors.orange
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

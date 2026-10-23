import 'dart:async';

import 'package:flutter/material.dart';

import 'package:renti/app/routes.dart';
import 'package:renti/core/services/auth_service.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';

/// Verificación del correo electrónico (cuentas con contraseña).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _comprobando = false;
  int _espera = 0; // segundos restantes para poder reenviar
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _yaVerifique() async {
    setState(() => _comprobando = true);
    try {
      final ok = await AuthService.instance.verificarCorreoActualizado();
      if (!mounted) return;
      if (!ok) {
        showSnack(context,
            'Todavía no vemos tu verificación. Abre el enlace del correo e inténtalo de nuevo.');
        return;
      }
      final fb = AuthService.instance.usuarioActual!;
      final destino = await appState.iniciarSesionDesde(fb);
      if (!mounted) return;
      AppRoutes.goTo(context, destino);
    } catch (e) {
      if (mounted) showSnack(context, AppState.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _comprobando = false);
    }
  }

  Future<void> _reenviar() async {
    try {
      await AuthService.instance.reenviarVerificacion();
      if (!mounted) return;
      showSnack(context, 'Te enviamos otro correo de verificación.');
      setState(() => _espera = 45);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _espera--);
        if (_espera <= 0) t.cancel();
      });
    } catch (e) {
      if (mounted) showSnack(context, AppState.mensajeDeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final correo = AuthService.instance.usuarioActual?.email ?? appState.userEmail;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: RentiTheme.pad),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  color: RentiColors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_rounded,
                    color: Colors.white, size: 56),
              ),
              const SizedBox(height: 28),
              Text(
                'Verifica tu correo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enviamos un enlace de verificación a\n$correo',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.muted, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                'Ábrelo y regresa aquí para continuar.',
                style: TextStyle(color: context.muted, fontSize: 15),
              ),
              const Spacer(flex: 2),
              PrimaryButton(
                label: 'Ya verifiqué mi correo',
                loading: _comprobando,
                onPressed: _yaVerifique,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: _espera > 0
                    ? 'Reenviar correo ($_espera s)'
                    : 'Reenviar correo',
                onPressed: _espera > 0 || _comprobando ? null : _reenviar,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed:
                    _comprobando ? null : () => AppRoutes.cerrarSesion(context),
                child: Text(
                  'Usar otra cuenta',
                  style: TextStyle(color: context.muted, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

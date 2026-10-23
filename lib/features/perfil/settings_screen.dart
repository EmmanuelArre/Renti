import 'package:flutter/material.dart';

import 'package:renti/core/services/auth_service.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';
import 'package:renti/core/widgets/state_widgets.dart';

/// 20 · Configuración: apariencia y seguridad de la cuenta.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _cambiarContrasena(BuildContext context) async {
    final user = appState.user;
    if (user == null) return;
    if (user.proveedor != 'password') {
      showSnack(context,
          'Tu cuenta usa Google; la contraseña se administra desde tu cuenta de Google.');
      return;
    }
    final ok = await confirmar(
      context,
      titulo: 'Cambiar contraseña',
      mensaje: 'Enviaremos un enlace a ${user.email} para que elijas una nueva contraseña.',
      aceptar: 'Enviar enlace',
    );
    if (!ok || !context.mounted) return;
    try {
      await AuthService.instance.recuperarContrasena(user.email);
      if (context.mounted) showSnack(context, 'Revisa tu correo.');
    } catch (e) {
      if (context.mounted) showSnack(context, AuthService.mensajeDe(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(RentiTheme.pad, 14, RentiTheme.pad, 24),
          children: [
            const ScreenHeader(title: 'Configuración'),
            const SectionTitle('Apariencia'),
            ListenableBuilder(
              listenable: appState,
              builder: (context, _) => Row(
                children: [
                  PillChip(
                    label: 'Modo claro',
                    selected: appState.themeMode == ThemeMode.light,
                    onTap: () => appState.setTheme(ThemeMode.light),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  ),
                  const SizedBox(width: 14),
                  PillChip(
                    label: 'Modo oscuro',
                    selected: appState.themeMode == ThemeMode.dark,
                    onTap: () => appState.setTheme(ThemeMode.dark),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  ),
                ],
              ),
            ),
            const SectionTitle('Cuenta'),
            InkWell(
              onTap: () => _cambiarContrasena(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: context.line, width: 1.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cambiar contraseña',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.ink,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: context.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Renti · versión 1.0.0',
              style: TextStyle(color: context.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

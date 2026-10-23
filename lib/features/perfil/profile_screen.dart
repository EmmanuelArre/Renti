import 'package:flutter/material.dart';

import 'package:renti/app/routes.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/features/perfil/edit_profile_screen.dart';
import 'package:renti/features/perfil/notifications_screen.dart';
import 'package:renti/features/perfil/settings_screen.dart';
import 'package:renti/shared/screens/messages_screen.dart';

/// 19 · Perfil (el mismo para los tres roles; cambian los accesos).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _abrir(BuildContext context, Widget pantalla) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => pantalla));

  Future<void> _salir(BuildContext context) async {
    final ok = await confirmar(
      context,
      titulo: 'Cerrar sesión',
      mensaje: '¿Quieres cerrar tu sesión?',
      aceptar: 'Cerrar sesión',
    );
    if (ok && context.mounted) await AppRoutes.cerrarSesion(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final unread = appState.unreadNotifications;
        final subtitulo = appState.university.isEmpty
            ? appState.roleLabel
            : '${appState.roleLabel} · ${appState.university}';
        final items = <(String, VoidCallback)>[
          ('Editar perfil', () => _abrir(context, const EditProfileScreen())),
          if (appState.isTenant) ...[
            ('❤️ Favoritos', () => appState.setTab(2)),
            ('🏠 Mis rentas', () => appState.setTab(3)),
          ],
          if (appState.isLandlord) ...[
            ('🏠 Mis propiedades', () => appState.setTab(1)),
            ('📥 Solicitudes', () => appState.setTab(2)),
          ],
          if (!appState.isAdmin)
            ('💬 Mensajes', () => _abrir(context, const MessagesScreen())),
          (
            unread > 0 ? '🔔 Notificaciones ($unread)' : '🔔 Notificaciones',
            () => _abrir(context, const NotificationsScreen())
          ),
          ('⚙️ Configuración', () => _abrir(context, const SettingsScreen())),
          ('🚪 Cerrar sesión', () => _salir(context)),
        ];
        return ListView(
          padding:
              const EdgeInsets.fromLTRB(RentiTheme.pad, 36, RentiTheme.pad, 24),
          children: [
            Center(child: Avatar(appState.user?.iniciales ?? '?', size: 92)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                appState.userName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: context.ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                subtitulo,
                style: TextStyle(
                  color: context.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                appState.userEmail,
                style: TextStyle(color: context.muted, fontSize: 14),
              ),
            ),
            const SizedBox(height: 28),
            for (final it in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: it.$2,
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.line, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            it.$1,
                            style: TextStyle(
                              fontSize: 16,
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
              ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/models/app_notification.dart';

/// Lista de avisos. Al abrirla se marcan como leídos.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Se conservan los no leídos al entrar para poder resaltarlos.
  late final Set<String> _nuevas = appState.notifications
      .where((n) => !n.read)
      .map((n) => n.id)
      .toSet();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => appState.marcarNotificacionesLeidas());
  }

  IconData _icono(String tipo) => switch (tipo) {
        'solicitud' => Icons.inbox_outlined,
        'arrendamiento' => Icons.home_outlined,
        'moderacion' => Icons.verified_outlined,
        'reporte' => Icons.flag_outlined,
        _ => Icons.notifications_none_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final lista = appState.notifications;
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(RentiTheme.pad, 14, RentiTheme.pad, 8),
                  child: ScreenHeader(title: 'Notificaciones'),
                ),
                Expanded(
                  child: lista.isEmpty
                      ? const EmptyView(
                          icon: Icons.notifications_off_outlined,
                          title: 'Sin notificaciones',
                          subtitle: 'Aquí aparecerán los avisos de tus solicitudes y publicaciones.',
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                              RentiTheme.pad, 8, RentiTheme.pad, 24),
                          children: [for (final n in lista) _tile(context, n)],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, AppNotification n) {
    final nueva = _nuevas.contains(n.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WhiteCard(
        padding: const EdgeInsets.all(16),
        border: nueva ? Border.all(color: RentiColors.orange, width: 1.5) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icono(n.type), color: RentiColors.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: context.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(n.message,
                      style: TextStyle(color: context.ink, height: 1.3)),
                  const SizedBox(height: 6),
                  Text(
                    formatDateTime(n.createdAt),
                    style: TextStyle(color: context.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';
import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/features/administrador/admin_stats_screen.dart';

/// Panel del administrador: resumen y accesos a lo que requiere atención.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final s = appState.stats;
        final first = appState.userName.split(' ').first;
        return RefreshList(
          children: [
            Text('Administración',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.muted)),
            const SizedBox(height: 2),
            Text('Hola, $first 👋',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: context.ink)),
            const SizedBox(height: 20),
            if (appState.loadError != null && s.usuarios == 0)
              ErrorView(
                  message: appState.loadError!, onRetry: appState.recargarAdmin)
            else ...[
              Row(children: [
                _Stat(RentiColors.blue, '${s.usuarios}', 'Usuarios'),
                const SizedBox(width: 12),
                _Stat(RentiColors.orange, '${s.propiedades}', 'Propiedades'),
                const SizedBox(width: 12),
                _Stat(RentiColors.green, '${s.arrendamientosActivos}', 'Rentas'),
              ]),
              const SizedBox(height: 20),
              _Alerta(
                numero: s.propiedadesPendientes,
                titulo: 'Publicaciones por revisar',
                detalle: 'Aprueba o rechaza lo nuevo',
                onTap: () => appState.setTab(2),
              ),
              const SizedBox(height: 12),
              _Alerta(
                numero: s.reportesAbiertos,
                titulo: 'Reportes abiertos',
                detalle: 'Resuélvelos o descártalos',
                onTap: () => appState.setTab(3),
              ),
              const SectionTitle('Estadísticas'),
              WhiteCard(
                padding: const EdgeInsets.all(18),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AdminStatsScreen())),
                child: Row(children: [
                  const Icon(Icons.bar_chart_rounded, color: RentiColors.blue),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Ver estadísticas detalladas',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: context.ink)),
                  ),
                  Icon(Icons.chevron_right_rounded, color: context.muted),
                ]),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Alerta extends StatelessWidget {
  final int numero;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;
  const _Alerta(
      {required this.numero,
      required this.titulo,
      required this.detalle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => WhiteCard(
        padding: const EdgeInsets.all(18),
        border: numero > 0
            ? Border.all(color: RentiColors.orange, width: 2)
            : null,
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: numero > 0 ? RentiColors.yellow : context.line,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$numero',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: RentiColors.ink)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.ink)),
                Text(detalle,
                    style: TextStyle(color: context.muted, fontSize: 14)),
              ],
            ),
          ),
        ]),
      );
}

class _Stat extends StatelessWidget {
  final Color dot;
  final String value;
  final String label;
  const _Stat(this.dot, this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(22),
            boxShadow: softShadow(0.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(height: 10),
              Text(value,
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: context.ink)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: TextStyle(
                        color: context.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ],
          ),
        ),
      );
}

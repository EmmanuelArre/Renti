import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/common_widgets.dart';

/// Estadísticas generales calculadas con consultas de conteo en Firestore.
class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final s = appState.stats;
            final filas = <(String, String)>[
              ('Usuarios totales', '${s.usuarios}'),
              ('Arrendadores', '${s.arrendadores}'),
              ('Estudiantes', '${s.arrendatarios}'),
              ('Propiedades totales', '${s.propiedades}'),
              ('· En revisión', '${s.propiedadesPendientes}'),
              ('· Aprobadas', '${s.propiedadesAprobadas}'),
              ('· Desactivadas', '${s.propiedadesDesactivadas}'),
              ('Solicitudes totales', '${s.solicitudes}'),
              ('· Pendientes', '${s.solicitudesPendientes}'),
              ('· Aceptadas', '${s.solicitudesAceptadas}'),
              ('Tasa de aceptación', '${s.tasaAceptacion} %'),
              ('Arrendamientos activos', '${s.arrendamientosActivos}'),
              ('Reportes abiertos', '${s.reportesAbiertos}'),
            ];
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  RentiTheme.pad, 14, RentiTheme.pad, 24),
              children: [
                const ScreenHeader(title: 'Estadísticas'),
                const SizedBox(height: 18),
                WhiteCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Column(
                    children: [
                      for (final f in filas)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          child: Row(children: [
                            Expanded(
                              child: Text(f.$1,
                                  style: TextStyle(
                                      color: context.ink, fontSize: 15.5)),
                            ),
                            Text(f.$2,
                                style: TextStyle(
                                    color: context.ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                          ]),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Arrastra hacia abajo en el panel para actualizar las cifras.',
                  style: TextStyle(color: context.muted, fontSize: 13),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

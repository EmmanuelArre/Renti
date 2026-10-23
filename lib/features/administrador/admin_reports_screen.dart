import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/models/report.dart';

/// Reportes enviados por usuarios: resolver o descartar con una nota.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  static const _filtros = ['Abiertos', 'Cerrados'];
  String _filtro = 'Abiertos';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final abiertos = _filtro == 'Abiertos';
        final lista =
            appState.reports.where((r) => r.isOpen == abiertos).toList();
        return RefreshList(
          children: [
            const BigTitle('Reportes'),
            const SizedBox(height: 14),
            FilterPills(
              options: _filtros,
              selected: _filtro,
              onChanged: (v) => setState(() => _filtro = v),
            ),
            const SizedBox(height: 16),
            if (appState.loading && appState.reports.isEmpty)
              const SizedBox(height: 200, child: LoadingView())
            else if (lista.isEmpty)
              const SizedBox(
                height: 260,
                child: EmptyView(
                  icon: Icons.flag_outlined,
                  title: 'Sin reportes',
                  subtitle: 'No hay reportes en esta lista.',
                ),
              )
            else
              for (final r in lista) _ReportCard(report: r),
          ],
        );
      },
    );
  }
}

class _ReportCard extends StatefulWidget {
  final Report report;
  const _ReportCard({required this.report});

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _ocupado = false;

  Future<void> _cerrar(String estado) async {
    final c = TextEditingController();
    final nota = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(estado == EstadoReporte.resuelto
            ? 'Resolver reporte'
            : 'Descartar reporte'),
        content: TextField(
          controller: c,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(hintText: 'Nota interna (opcional)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Confirmar')),
        ],
      ),
    );
    c.dispose();
    if (nota == null || !mounted) return;
    setState(() => _ocupado = true);
    final error = await appState.resolverReporte(widget.report, estado, nota);
    if (!mounted) return;
    setState(() => _ocupado = false);
    showSnack(context, error ?? 'Reporte actualizado');
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: WhiteCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(r.targetName.isEmpty ? '(sin nombre)' : r.targetName,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.ink)),
              ),
              StatusBadge(
                r.status.toUpperCase(),
                color: r.isOpen ? RentiColors.orange : RentiColors.green,
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              '${r.type == TipoReporte.propiedad ? 'Propiedad' : 'Usuario'}'
              ' · reportó ${r.reporterName}',
              style: TextStyle(color: context.muted, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            Text(r.reason,
                style: TextStyle(
                    color: context.ink, fontWeight: FontWeight.w700)),
            if (r.details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(r.details,
                  style: TextStyle(color: context.ink, height: 1.3)),
            ],
            if (!r.isOpen && r.resolution.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Nota: ${r.resolution}',
                  style: TextStyle(
                      color: context.muted, fontStyle: FontStyle.italic)),
            ],
            if (r.isOpen) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Resolver',
                    height: 42,
                    color: RentiColors.green,
                    loading: _ocupado,
                    onPressed:
                        _ocupado ? null : () => _cerrar(EstadoReporte.resuelto),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: 'Descartar',
                    height: 42,
                    onPressed: _ocupado
                        ? null
                        : () => _cerrar(EstadoReporte.descartado),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

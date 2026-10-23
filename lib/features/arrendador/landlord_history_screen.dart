import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/models/rental.dart';
import 'package:renti/shared/screens/chat_screen.dart';

/// Historial de arrendamientos del arrendador (activos y finalizados).
class LandlordHistoryScreen extends StatelessWidget {
  const LandlordHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final lista = appState.rentals;
        return RefreshList(
          children: [
            const BigTitle('Historial'),
            const SizedBox(height: 22),
            if (appState.loading && lista.isEmpty)
              const SizedBox(height: 200, child: LoadingView())
            else if (lista.isEmpty)
              const SizedBox(
                height: 320,
                child: EmptyView(
                  icon: Icons.history_rounded,
                  title: 'Aún no hay arrendamientos',
                  subtitle: 'Aquí verás las rentas que aceptes y las que ya terminaron.',
                ),
              )
            else
              for (final r in lista) _HistoryCard(rental: r),
          ],
        );
      },
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final Rental rental;
  const _HistoryCard({required this.rental});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _ocupado = false;

  Future<void> _finalizar() async {
    final r = widget.rental;
    final ok = await confirmar(
      context,
      titulo: 'Finalizar arrendamiento',
      mensaje: '¿Marcar como finalizada la renta de "${r.listingTitle}" con '
          '${r.tenantName}? La propiedad volverá a estar disponible.',
      aceptar: 'Finalizar',
    );
    if (!ok || !mounted) return;
    setState(() => _ocupado = true);
    final error = await appState.finalizarArrendamiento(r);
    if (!mounted) return;
    setState(() => _ocupado = false);
    showSnack(context, error ?? 'Arrendamiento finalizado');
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rental;
    final activa = r.state == RentalState.activa;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: WhiteCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.listingTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.ink,
                    ),
                  ),
                ),
                StatusBadge(
                  activa ? 'ACTIVA' : 'FINALIZADA',
                  color: activa ? RentiColors.green : context.muted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Estudiante: ${r.tenantName}',
              style: TextStyle(
                  color: context.ink, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatDate(r.start)} — ${r.months == 0 ? 'Indefinido' : formatDate(r.end)}',
              style: TextStyle(color: context.muted, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatMoney(r.monthlyPrice)} / mes',
              style: const TextStyle(
                color: RentiColors.orange,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Escribir',
                    height: 42,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(otherId: r.tenantId, name: r.tenantName),
                      ),
                    ),
                  ),
                ),
                if (activa) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Finalizar',
                      height: 42,
                      shadow: false,
                      loading: _ocupado,
                      onPressed: _ocupado ? null : _finalizar,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

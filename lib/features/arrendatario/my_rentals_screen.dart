import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';
import 'package:renti/core/widgets/listing_widgets.dart';
import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/features/arrendatario/rental_detail_screen.dart';
import 'package:renti/models/rental.dart';

enum _Pestana { solicitudes, activas, historial }

/// 14 · Mis rentas: solicitudes enviadas, rentas activas e historial.
class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  _Pestana _tab = _Pestana.solicitudes;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final solicitudes = appState.requests;
        final activas = appState.rentals
            .where((r) => r.state == RentalState.activa)
            .toList();
        final historial = appState.rentals
            .where((r) => r.state == RentalState.finalizada)
            .toList();
        final vacio = switch (_tab) {
          _Pestana.solicitudes => solicitudes.isEmpty,
          _Pestana.activas => activas.isEmpty,
          _Pestana.historial => historial.isEmpty,
        };
        return RefreshList(
          children: [
            const BigTitle('Mis rentas'),
            const SizedBox(height: 22),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  PillChip(
                    label: 'Solicitudes (${solicitudes.length})',
                    selected: _tab == _Pestana.solicitudes,
                    onTap: () => setState(() => _tab = _Pestana.solicitudes),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  ),
                  const SizedBox(width: 10),
                  PillChip(
                    label: 'Activas',
                    selected: _tab == _Pestana.activas,
                    onTap: () => setState(() => _tab = _Pestana.activas),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  ),
                  const SizedBox(width: 10),
                  PillChip(
                    label: 'Historial',
                    selected: _tab == _Pestana.historial,
                    onTap: () => setState(() => _tab = _Pestana.historial),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (appState.loading && vacio)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: LoadingView(),
              )
            else if (vacio)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EmptyView(
                  icon: Icons.event_busy_rounded,
                  title: switch (_tab) {
                    _Pestana.solicitudes => 'Aún no has enviado solicitudes',
                    _Pestana.activas => 'Aún no tienes rentas activas',
                    _Pestana.historial => 'Tu historial está vacío',
                  },
                  subtitle: _tab == _Pestana.solicitudes
                      ? 'Busca un alojamiento y solicita tu renta.'
                      : null,
                  actionLabel:
                      _tab == _Pestana.solicitudes ? 'Explorar alojamientos' : null,
                  onAction: _tab == _Pestana.solicitudes
                      ? () => appState.setTab(1)
                      : null,
                ),
              )
            else ...[
              if (_tab == _Pestana.solicitudes)
                for (final s in solicitudes) _RequestCard(request: s),
              if (_tab == _Pestana.activas)
                for (final r in activas) _RentalCard(rental: r),
              if (_tab == _Pestana.historial)
                for (final r in historial) _RentalCard(rental: r),
            ],
          ],
        );
      },
    );
  }
}

Color _colorEstado(BuildContext context, String estado) {
  switch (estado) {
    case EstadoSolicitud.aceptada:
      return RentiColors.green;
    case EstadoSolicitud.pendiente:
      return RentiColors.yellow;
    case EstadoSolicitud.rechazada:
      return RentiColors.orange;
    default:
      return context.muted;
  }
}

class _RequestCard extends StatefulWidget {
  final RentalRequest request;
  const _RequestCard({required this.request});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _cancelando = false;

  Future<void> _cancelar() async {
    final ok = await confirmar(
      context,
      titulo: 'Cancelar solicitud',
      mensaje: '¿Seguro que quieres cancelar tu solicitud para '
          '"${widget.request.listingTitle}"?',
      aceptar: 'Cancelar solicitud',
      peligroso: true,
    );
    if (!ok || !mounted) return;
    setState(() => _cancelando = true);
    final error = await appState.cancelarSolicitud(widget.request);
    if (!mounted) return;
    setState(() => _cancelando = false);
    showSnack(context, error ?? 'Solicitud cancelada');
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final pendiente = r.status == EstadoSolicitud.pendiente;
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
                  r.status,
                  color: _colorEstado(context, r.status),
                  textColor: pendiente ? RentiColors.ink : Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '📅 ${formatDate(r.entryDate)} · ⏳ '
              '${r.months == 0 ? 'Indefinido' : '${r.months} meses'}',
              style: TextStyle(
                color: context.muted,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
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
            if (pendiente) ...[
              const SizedBox(height: 14),
              SecondaryButton(
                label: _cancelando ? 'Cancelando...' : 'Cancelar solicitud',
                height: 44,
                textColor: Colors.redAccent,
                onPressed: _cancelando ? null : _cancelar,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RentalCard extends StatelessWidget {
  final Rental rental;
  const _RentalCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    final active = rental.state == RentalState.activa;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: WhiteCard(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListingImage(
                  width: 90,
                  height: 90,
                  radius: BorderRadius.all(Radius.circular(18)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.listingTitle,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: context.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StatusBadge(
                        active ? 'ACTIVA' : 'FINALIZADA',
                        color: active ? RentiColors.green : context.muted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${formatDate(rental.start)} — ${formatDate(rental.end)}',
                        style: TextStyle(
                          color: context.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatMoney(rental.monthlyPrice)} / mes',
                        style: const TextStyle(
                          color: RentiColors.orange,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'Ver detalles',
              height: 46,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => RentalDetailScreen(rental: rental)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

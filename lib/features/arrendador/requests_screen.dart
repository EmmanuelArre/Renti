import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/models/rental.dart';
import 'package:renti/shared/screens/chat_screen.dart';

/// 24 · Solicitudes recibidas
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final lista = appState.requests;
        return RefreshList(
          children: [
            const BigTitle('Solicitudes'),
            const SizedBox(height: 22),
            if (appState.loading && lista.isEmpty)
              const SizedBox(height: 200, child: LoadingView())
            else if (lista.isEmpty)
              const SizedBox(
                height: 320,
                child: EmptyView(
                  icon: Icons.inbox_outlined,
                  title: 'Todavía no tienes solicitudes',
                  subtitle:
                      'Cuando un estudiante pida rentar una de tus propiedades aparecerá aquí.',
                ),
              )
            else
              for (final r in lista) _RequestCard(request: r),
          ],
        );
      },
    );
  }
}

class _RequestCard extends StatefulWidget {
  final RentalRequest request;
  const _RequestCard({required this.request});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _ocupado = false;

  Future<void> _responder(bool aceptar) async {
    final r = widget.request;
    final ok = await confirmar(
      context,
      titulo: aceptar ? 'Aceptar solicitud' : 'Rechazar solicitud',
      mensaje: aceptar
          ? 'Al aceptar, "${r.listingTitle}" quedará como rentada a '
              '${r.tenantName} y las demás solicitudes pendientes de esa '
              'propiedad se rechazarán.'
          : '¿Rechazar la solicitud de ${r.tenantName}?',
      aceptar: aceptar ? 'Aceptar' : 'Rechazar',
      peligroso: !aceptar,
    );
    if (!ok || !mounted) return;
    setState(() => _ocupado = true);
    final error = await appState.responderSolicitud(r, aceptar);
    if (!mounted) return;
    setState(() => _ocupado = false);
    showSnack(
        context,
        error ?? (aceptar ? 'Solicitud aceptada' : 'Solicitud rechazada'));
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final pending = request.isPending;
    final accepted = request.status == EstadoSolicitud.aceptada;
    final initials = request.tenantName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0])
        .join();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: WhiteCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(initials, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.tenantName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.listingTitle,
                        style: TextStyle(
                          color: context.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  request.status,
                  color: pending
                      ? RentiColors.yellow
                      : accepted
                          ? RentiColors.green
                          : RentiColors.orange,
                  textColor: pending ? RentiColors.ink : Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '⏳ ${request.months == 0 ? 'Indefinido' : '${request.months} meses'}'
              ' · 📅 ${formatDate(request.entryDate)}'
              ' · ${formatMoney(request.monthlyPrice)}/mes',
              style: TextStyle(
                color: context.muted,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            if (request.message.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '“${request.message}”',
                style: TextStyle(
                  color: context.ink,
                  fontSize: 14.5,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Pago preferido: ${request.paymentMethod}',
              style: TextStyle(color: context.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Escribir al estudiante',
              height: 42,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherId: request.tenantId,
                    name: request.tenantName,
                  ),
                ),
              ),
            ),
            if (pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Aceptar',
                      height: 46,
                      color: RentiColors.green,
                      loading: _ocupado,
                      onPressed: _ocupado ? null : () => _responder(true),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Rechazar',
                      height: 46,
                      shadow: false,
                      onPressed: _ocupado ? null : () => _responder(false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';
import 'package:renti/features/arrendatario/confirmation_screen.dart';
import 'package:renti/models/listing.dart';

/// 12 · Resumen y pago
///
/// Renti todavía NO procesa pagos en línea: aquí solo se elige cómo se
/// pretende pagar y se envía la solicitud. El pago real se acuerda
/// directamente con el arrendador cuando acepta.
class PaymentScreen extends StatefulWidget {
  final Listing listing;
  final DurationOption option;
  final DateTime entry;
  final String message;
  const PaymentScreen({
    super.key,
    required this.listing,
    required this.option,
    required this.entry,
    this.message = '',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _metodo = Catalogos.metodosPago.first;
  bool _enviando = false;

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final r = await appState.enviarSolicitud(
      propiedad: widget.listing,
      opcion: widget.option,
      fechaIngreso: widget.entry,
      mensaje: widget.message,
      metodoPago: _metodo,
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (r.error != null || r.request == null) {
      showSnack(context, r.error ?? 'No se pudo enviar la solicitud.');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ConfirmationScreen(request: r.request!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rent = widget.option.pricePerMonth;
    final total = rent * 2; // primera renta + depósito
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    RentiTheme.pad, 14, RentiTheme.pad, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ScreenHeader(title: 'Resumen y pago'),
                    const SizedBox(height: 18),
                    DetailRow('Alojamiento', widget.listing.title),
                    DetailRow('Entrada', formatDate(widget.entry)),
                    DetailRow('Renta', formatMoney(rent)),
                    DetailRow('Depósito', formatMoney(rent)),
                    Divider(color: context.line, height: 36, thickness: 1.5),
                    Row(
                      children: [
                        Text(
                          'Total inicial',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: context.ink,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatMoney(total),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: RentiColors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Forma de pago preferida',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: context.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    PillWrap(
                      options: Catalogos.metodosPago,
                      isSelected: (o) => o == _metodo,
                      onTap: (o) => setState(() => _metodo = o),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: RentiColors.yellow.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: RentiColors.ink, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Aún no se cobra nada en la app. Al enviar la '
                              'solicitud el arrendador la revisará y, si la '
                              'acepta, acordarán el pago directamente.',
                              style: TextStyle(
                                color: context.ink,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(RentiTheme.pad, 8, RentiTheme.pad, 16),
              child: PrimaryButton(
                label: 'Enviar solicitud',
                loading: _enviando,
                onPressed: _enviar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

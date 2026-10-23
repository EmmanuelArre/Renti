import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/models/rental.dart';
import 'package:renti/shared/screens/chat_screen.dart';
import 'package:renti/shared/widgets/report_sheet.dart';

/// 15 · Detalle de renta
class RentalDetailScreen extends StatelessWidget {
  final Rental rental;
  const RentalDetailScreen({super.key, required this.rental});

  /// Siguiente fecha de pago mensual a partir de hoy.
  DateTime get _proximoPago {
    final hoy = DateTime.now();
    var d = addMonths(rental.start, 1);
    var n = 1;
    while (d.isBefore(DateTime(hoy.year, hoy.month, hoy.day)) && n < 600) {
      n++;
      d = addMonths(rental.start, n);
    }
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final active = rental.state == RentalState.activa;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(RentiTheme.pad, 14, RentiTheme.pad, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Mi renta'),
              const SizedBox(height: 18),
              StatusBadge(
                active ? 'ACTIVA' : 'FINALIZADA',
                color: active ? RentiColors.green : context.muted,
              ),
              const SizedBox(height: 14),
              WhiteCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Column(
                  children: [
                    DetailRow('Alojamiento', rental.listingTitle),
                    DetailRow('Dirección', rental.address),
                    DetailRow('Arrendador', rental.landlordName),
                    DetailRow('Fecha de entrada', formatDate(rental.start)),
                    DetailRow(
                      'Fecha de finalización',
                      rental.months == 0 ? 'Indefinida' : formatDate(rental.end),
                    ),
                    DetailRow(
                      'Duración',
                      rental.months == 0 ? 'Indefinido' : '${rental.months} meses',
                    ),
                    DetailRow('Precio mensual',
                        '${formatMoney(rental.monthlyPrice)} / mes'),
                  ],
                ),
              ),
              if (active) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: RentiColors.blue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próximo pago',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatMoney(rental.monthlyPrice),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              formatDate(_proximoPago),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SecondaryButton(
                label: 'Contactar arrendador',
                height: 52,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      otherId: rental.landlordId,
                      name: rental.landlordName,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Ver contrato',
                height: 52,
                textColor: RentiColors.blue,
                borderColor: RentiColors.blue,
                onPressed: () =>
                    showSnack(context, 'El contrato estará disponible pronto'),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Reportar problema',
                height: 52,
                shadow: false,
                onPressed: () => mostrarReporte(
                  context,
                  tipo: TipoReporte.propiedad,
                  objetivoId: rental.listingId,
                  objetivoNombre: rental.listingTitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

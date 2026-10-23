import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/models/rental.dart';

/// 13 · Confirmación de solicitud enviada
class ConfirmationScreen extends StatelessWidget {
  final RentalRequest request;
  const ConfirmationScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: RentiTheme.pad),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: RentiColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 72),
              ),
              const SizedBox(height: 32),
              Text(
                '¡Solicitud enviada! 🎉',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El arrendador revisará tu solicitud.\nTe avisaremos cuando responda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: context.muted, height: 1.4),
              ),
              const SizedBox(height: 32),
              WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Column(
                  children: [
                    DetailRow('Alojamiento', request.listingTitle),
                    DetailRow('Entrada', formatDate(request.entryDate)),
                    DetailRow(
                      'Duración',
                      request.months == 0 ? 'Indefinido' : '${request.months} meses',
                    ),
                    DetailRow('Precio mensual',
                        '${formatMoney(request.monthlyPrice)} / mes'),
                    DetailRow('Estado', request.status),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'Ver mis solicitudes',
                onPressed: () {
                  appState.setTab(3);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

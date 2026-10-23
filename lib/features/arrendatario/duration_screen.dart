import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/features/arrendatario/request_screen.dart';

/// 10 · Elegir duración
class DurationScreen extends StatefulWidget {
  final Listing listing;
  const DurationScreen({super.key, required this.listing});

  @override
  State<DurationScreen> createState() => _DurationScreenState();
}

class _DurationScreenState extends State<DurationScreen> {
  int _selected = 2; // 6 meses, como en el diseño

  @override
  Widget build(BuildContext context) {
    final options = widget.listing.durations;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(RentiTheme.pad, 14, RentiTheme.pad, 16),
                children: [
                  const ScreenHeader(title: 'Elegir duración'),
                  const SizedBox(height: 22),
                  Text(
                    '¿Cuánto tiempo\nquieres quedarte?',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: context.ink,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (var i = 0; i < options.length; i++)
                    _DurationCard(
                      option: options[i],
                      selected: i == _selected,
                      onTap: () => setState(() => _selected = i),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(RentiTheme.pad, 8, RentiTheme.pad, 16),
              child: PrimaryButton(
                label: 'Continuar',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RequestScreen(
                      listing: widget.listing,
                      option: options[_selected],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  final DurationOption option;
  final bool selected;
  final VoidCallback onTap;
  const _DurationCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? RentiColors.blue : context.line,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: softShadow(0.08),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: RentiColors.blue, width: 2.5),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: RentiColors.blue,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${formatMoney(option.pricePerMonth)} / mes',
                    style: const TextStyle(
                      color: RentiColors.orange,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (option.savingsPercent > 0)
              StatusBadge('Ahorra ${option.savingsPercent}%'),
          ],
        ),
      ),
    );
  }
}

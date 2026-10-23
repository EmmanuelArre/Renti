import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';
import 'package:renti/core/widgets/listing_widgets.dart';
import 'package:renti/features/arrendatario/payment_screen.dart';
import 'package:renti/models/listing.dart';

/// 11 · Solicitud de renta
class RequestScreen extends StatefulWidget {
  final Listing listing;
  final DurationOption option;
  const RequestScreen({super.key, required this.listing, required this.option});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();
  bool _accepted = true;
  late DateTime _entry = _fechaInicial();
  String? _errorFecha;

  static DateTime _hoy() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _fechaInicial() {
    final elegida = appState.filters.entryDate;
    if (elegida != null && Validators.fechaIngreso(elegida) == null) {
      return elegida;
    }
    return _hoy().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final hoy = _hoy();
    final d = await showDatePicker(
      context: context,
      initialDate: _entry.isBefore(hoy) ? hoy : _entry,
      firstDate: hoy,
      lastDate: DateTime(hoy.year + 2),
    );
    if (d != null) {
      setState(() {
        _entry = d;
        _errorFecha = null;
      });
    }
  }

  void _continuar() {
    final ok = _form.currentState!.validate();
    final errFecha = Validators.fechaIngreso(_entry);
    setState(() => _errorFecha = errFecha);
    if (!ok || errFecha != null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          listing: widget.listing,
          option: widget.option,
          entry: _entry,
          message: _message.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.option;
    final exit = o.months == 0
        ? 'Indefinida'
        : formatDate(addMonths(_entry, o.months)
            .subtract(const Duration(days: 1)));
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    RentiTheme.pad, 14, RentiTheme.pad, 16),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScreenHeader(title: 'Solicitar renta'),
                      const SizedBox(height: 24),
                      WhiteCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListingImage(
                              width: 80,
                              height: 80,
                              photo: widget.listing.cover,
                              radius:
                                  const BorderRadius.all(Radius.circular(16)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.listing.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: context.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _mini(context, 'Duración', o.label),
                                  _mini(context, 'Precio mensual',
                                      '${formatMoney(o.pricePerMonth)} / mes'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TappableField(
                        label: 'Fecha de entrada',
                        text: formatDate(_entry),
                        isHint: false,
                        errorText: _errorFecha,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 14),
                      _InfoField('Fecha de salida', exit),
                      const SizedBox(height: 12),
                      _InfoField('Depósito', formatMoney(o.pricePerMonth)),
                      RentiTextField(
                        label: 'Mensaje al arrendador',
                        hint: 'Cuéntale al arrendador sobre ti...',
                        controller: _message,
                        maxLines: 3,
                        maxLength: 400,
                        validator: Validators.mensajeSolicitud,
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () => setState(() => _accepted = !_accepted),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _accepted
                                    ? RentiColors.blue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _accepted
                                      ? RentiColors.blue
                                      : context.muted,
                                  width: 1.8,
                                ),
                              ),
                              child: _accepted
                                  ? const Icon(Icons.check_rounded,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Acepto los términos y condiciones',
                              style: TextStyle(color: context.ink, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(RentiTheme.pad, 8, RentiTheme.pad, 16),
              child: PrimaryButton(
                label: 'Continuar',
                onPressed: _accepted ? _continuar : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(BuildContext context, String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(l, style: TextStyle(color: context.muted, fontSize: 13)),
            ),
            Text(
              v,
              style: TextStyle(
                color: context.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  const _InfoField(this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.line, width: 1.5),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: context.muted,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: context.ink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
}

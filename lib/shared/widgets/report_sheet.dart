import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';

/// Hoja inferior para reportar una propiedad o a una persona.
Future<void> mostrarReporte(
  BuildContext context, {
  required String tipo,
  required String objetivoId,
  required String objetivoNombre,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _ReportSheet(
        tipo: tipo,
        objetivoId: objetivoId,
        objetivoNombre: objetivoNombre,
      ),
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  final String tipo;
  final String objetivoId;
  final String objetivoNombre;
  const _ReportSheet({
    required this.tipo,
    required this.objetivoId,
    required this.objetivoNombre,
  });

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _form = GlobalKey<FormState>();
  final _detalle = TextEditingController();
  String? _motivo;
  String? _errorMotivo;
  bool _enviando = false;

  @override
  void dispose() {
    _detalle.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final ok = _form.currentState!.validate();
    final errMotivo = Validators.motivoReporte(_motivo);
    setState(() => _errorMotivo = errMotivo);
    if (!ok || errMotivo != null) return;
    setState(() => _enviando = true);
    final error = await appState.enviarReporte(
      tipo: widget.tipo,
      objetivoId: widget.objetivoId,
      objetivoNombre: widget.objetivoNombre,
      motivo: _motivo!,
      detalle: _detalle.text,
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    nav.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Reporte enviado. Gracias por avisarnos.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(RentiTheme.pad, 22, RentiTheme.pad, 24),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reportar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.objetivoNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.muted, fontSize: 15),
            ),
            SelectField(
              label: 'Motivo',
              hint: 'Selecciona un motivo',
              value: _motivo,
              options: Catalogos.motivosReporte,
              errorText: _errorMotivo,
              onChanged: (v) => setState(() {
                _motivo = v;
                _errorMotivo = null;
              }),
            ),
            RentiTextField(
              label: 'Cuéntanos qué pasó',
              hint: 'Describe el problema...',
              controller: _detalle,
              maxLines: 4,
              maxLength: 500,
              validator: Validators.detalleReporte,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Enviar reporte',
              loading: _enviando,
              onPressed: _enviar,
            ),
          ],
        ),
      ),
    );
  }
}

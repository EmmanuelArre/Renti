import 'package:flutter/material.dart';

import 'package:renti/core/services/auth_service.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';

/// Recuperación de contraseña: Firebase envía un enlace al correo.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _cargando = false;
  bool _enviado = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await AuthService.instance
          .recuperarContrasena(Validators.normalizarCorreo(_email.text));
      if (mounted) setState(() => _enviado = true);
    } catch (e) {
      final texto = AppState.mensajeDeError(e);
      // Por privacidad no se revela si el correo existe o no.
      final noExiste = texto.contains('incorrectos');
      if (mounted) {
        if (noExiste) {
          setState(() => _enviado = true);
        } else {
          setState(() => _error = texto);
        }
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(RentiTheme.pad, 14, RentiTheme.pad, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(title: 'Recuperar contraseña'),
                const SizedBox(height: 22),
                if (_enviado) ...[
                  const Center(
                    child: Icon(Icons.mark_email_read_rounded,
                        size: 72, color: RentiColors.green),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Revisa tu correo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: context.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Si ${_email.text.trim()} tiene una cuenta, recibirás un '
                    'enlace para crear una nueva contraseña. Revisa también '
                    'la carpeta de spam.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.muted, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Volver a iniciar sesión',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ] else ...[
                  Text(
                    'Escribe el correo de tu cuenta y te enviaremos un enlace '
                    'para restablecer tu contraseña.',
                    style: TextStyle(color: context.muted, fontSize: 15, height: 1.4),
                  ),
                  RentiTextField(
                    label: 'Correo electrónico',
                    hint: 'tucorreo@universidad.edu',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.correo,
                    onSubmitted: (_) => _enviar(),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  const SizedBox(height: 26),
                  PrimaryButton(
                    label: 'Enviar enlace',
                    loading: _cargando,
                    onPressed: _enviar,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

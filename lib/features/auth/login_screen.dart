import 'package:flutter/material.dart';

import 'package:renti/app/routes.dart';
import 'package:renti/core/services/auth_service.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';

/// Inicio de sesión con correo y contraseña o con cuenta de Google.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _cargando = false;
  bool _cargandoGoogle = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  bool get _ocupado => _cargando || _cargandoGoogle;

  Future<void> _entrarConCorreo() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final fb = await AuthService.instance.iniciarConCorreo(
        correo: Validators.normalizarCorreo(_email.text),
        contrasena: _pass.text,
      );
      final destino = await appState.iniciarSesionDesde(fb);
      if (!mounted) return;
      AppRoutes.goTo(context, destino);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppState.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _entrarConGoogle() async {
    setState(() {
      _cargandoGoogle = true;
      _error = null;
    });
    try {
      final fb = await AuthService.instance.iniciarConGoogle();
      if (fb == null) return; // la persona cerró la ventana de Google
      final destino = await appState.iniciarSesionDesde(fb);
      if (!mounted) return;
      AppRoutes.goTo(context, destino);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppState.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargandoGoogle = false);
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
                const ScreenHeader(title: 'Iniciar sesión'),
                const SizedBox(height: 18),
                Text(
                  'Bienvenido de vuelta 👋',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: context.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Entra para ver tus rentas, solicitudes y mensajes.',
                  style: TextStyle(color: context.muted, fontSize: 15),
                ),
                RentiTextField(
                  label: 'Correo electrónico',
                  hint: 'tucorreo@universidad.edu',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.correo,
                  enabled: !_ocupado,
                ),
                RentiTextField(
                  label: 'Contraseña',
                  hint: '••••••••',
                  controller: _pass,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) =>
                      (v ?? '').isEmpty ? 'Escribe tu contraseña' : null,
                  onSubmitted: (_) => _entrarConCorreo(),
                  enabled: !_ocupado,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _ocupado
                        ? null
                        : () => Navigator.of(context)
                            .pushNamed(AppRoutes.forgotPassword),
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: RentiColors.blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (_error != null) _ErrorBox(_error!),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Iniciar sesión',
                  loading: _cargando,
                  onPressed: _ocupado ? null : _entrarConCorreo,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: Divider(color: context.line, thickness: 1.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('o',
                          style: TextStyle(
                              color: context.muted, fontWeight: FontWeight.w700)),
                    ),
                    Expanded(child: Divider(color: context.line, thickness: 1.5)),
                  ],
                ),
                const SizedBox(height: 18),
                GoogleButton(
                  loading: _cargandoGoogle,
                  onPressed: _ocupado ? null : _entrarConGoogle,
                ),
                const SizedBox(height: 22),
                Center(
                  child: GestureDetector(
                    onTap: _ocupado
                        ? null
                        : () => Navigator.of(context)
                            .pushReplacementNamed(AppRoutes.register),
                    child: Text.rich(
                      TextSpan(
                        text: '¿No tienes cuenta? ',
                        style: TextStyle(color: context.muted, fontSize: 15),
                        children: const [
                          TextSpan(
                            text: 'Regístrate',
                            style: TextStyle(
                              color: RentiColors.blue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: context.ink, fontSize: 14, height: 1.3),
              ),
            ),
          ],
        ),
      );
}

/// Botón "Continuar con Google" (sin depender de imágenes externas).
class GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  const GoogleButton({super.key, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null && !loading ? 0.5 : 1,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.line, width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: loading ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continuar con Google',
                          style: TextStyle(
                            color: context.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

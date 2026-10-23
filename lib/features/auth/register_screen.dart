import 'package:flutter/material.dart';

import 'package:renti/app/routes.dart';
import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/services/auth_service.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';
import 'package:renti/features/auth/login_screen.dart' show GoogleButton;

/// 03 · Registro con correo y contraseña (o con Google).
///
/// Solo se puede elegir "estudiante" (arrendatario) o "arrendador": la cuenta
/// de administrador nunca se crea desde aquí.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  String? _university;
  String _rol = Roles.arrendatario;
  bool _cargando = false;
  bool _cargandoGoogle = false;
  String? _errorUniversidad;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _ocupado => _cargando || _cargandoGoogle;

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    final formOk = _form.currentState!.validate();
    final univError = (_rol == Roles.arrendatario && _university == null)
        ? 'Selecciona tu universidad'
        : null;
    setState(() {
      _errorUniversidad = univError;
      _error = null;
    });
    if (!formOk || univError != null) return;

    setState(() => _cargando = true);
    try {
      final nombre = Validators.normalizarEspacios(_name.text);
      final fb = await AuthService.instance.registrarConCorreo(
        nombre: nombre,
        correo: Validators.normalizarCorreo(_email.text),
        contrasena: _pass.text,
      );
      try {
        final destino = await appState.crearPerfil(
          fb: fb,
          nombre: nombre,
          rol: _rol,
          universidad: _university ?? '',
        );
        if (!mounted) return;
        AppRoutes.goTo(context, destino);
      } catch (e) {
        // La cuenta de acceso se creó pero el perfil no: al volver a entrar
        // la app pedirá completarlo.
        if (!mounted) return;
        setState(() => _error =
            '${AppState.mensajeDeError(e)} Inicia sesión para completar tu perfil.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppState.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _registrarConGoogle() async {
    setState(() {
      _cargandoGoogle = true;
      _error = null;
    });
    try {
      final fb = await AuthService.instance.iniciarConGoogle();
      if (fb == null) return;
      // Si es la primera vez, el destino será "elegir rol".
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
                const ScreenHeader(title: 'Crear cuenta'),
                RentiTextField(
                  label: 'Nombre completo',
                  hint: 'Ej. María López',
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.nombreCompleto,
                  enabled: !_ocupado,
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
                  hint: 'Mínimo 8 caracteres',
                  controller: _pass,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.contrasena,
                  enabled: !_ocupado,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 0, 0),
                  child: Text(
                    'Usa mayúsculas, minúsculas y al menos un número.',
                    style: TextStyle(color: context.muted, fontSize: 12.5),
                  ),
                ),
                RentiTextField(
                  label: 'Confirmar contraseña',
                  hint: 'Repite tu contraseña',
                  controller: _pass2,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.confirmarContrasena(v, _pass.text),
                  enabled: !_ocupado,
                ),
                const FieldLabel('Quiero registrarme como'),
                Row(
                  children: [
                    Expanded(
                      child: PillChip(
                        label: 'Soy estudiante',
                        selected: _rol == Roles.arrendatario,
                        onTap: () => setState(() => _rol = Roles.arrendatario),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PillChip(
                        label: 'Soy arrendador',
                        selected: _rol == Roles.arrendador,
                        onTap: () => setState(() => _rol = Roles.arrendador),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
                SelectField(
                  label: _rol == Roles.arrendatario
                      ? 'Universidad'
                      : 'Universidad (opcional)',
                  hint: 'Selecciona tu universidad',
                  value: _university,
                  options: Catalogos.universidades,
                  errorText: _errorUniversidad,
                  onChanged: (v) => setState(() {
                    _university = v;
                    _errorUniversidad = null;
                  }),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 14, height: 1.3),
                    ),
                  ),
                const SizedBox(height: 26),
                PrimaryButton(
                  label: 'Crear cuenta',
                  loading: _cargando,
                  onPressed: _ocupado ? null : _registrar,
                ),
                const SizedBox(height: 14),
                GoogleButton(
                  loading: _cargandoGoogle,
                  onPressed: _ocupado ? null : _registrarConGoogle,
                ),
                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: _ocupado
                        ? null
                        : () => Navigator.of(context)
                            .pushReplacementNamed(AppRoutes.login),
                    child: Text.rich(
                      TextSpan(
                        text: '¿Ya tienes cuenta? ',
                        style: TextStyle(color: context.muted, fontSize: 15),
                        children: const [
                          TextSpan(
                            text: 'Inicia sesión',
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

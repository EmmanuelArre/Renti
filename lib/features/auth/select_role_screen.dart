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

/// Completa el perfil la primera vez que alguien entra (por ejemplo con
/// Google): nombre, tipo de usuario y universidad.
class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: appState.nombrePendiente);
  String _rol = Roles.arrendatario;
  String? _university;
  String? _errorUniversidad;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    FocusScope.of(context).unfocus();
    final ok = _form.currentState!.validate();
    final univError = (_rol == Roles.arrendatario && _university == null)
        ? 'Selecciona tu universidad'
        : null;
    setState(() {
      _errorUniversidad = univError;
      _error = null;
    });
    if (!ok || univError != null) return;

    final fb = AuthService.instance.usuarioActual;
    if (fb == null) {
      AppRoutes.goTo(context, Destino.bienvenida);
      return;
    }
    setState(() => _cargando = true);
    try {
      final destino = await appState.crearPerfil(
        fb: fb,
        nombre: _name.text,
        rol: _rol,
        universidad: _university ?? '',
      );
      if (!mounted) return;
      AppRoutes.goTo(context, destino);
    } catch (e) {
      if (mounted) setState(() => _error = AppState.mensajeDeError(e));
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
                const ScreenHeader(title: 'Completa tu perfil', showBack: false),
                const SizedBox(height: 18),
                Text(
                  'Un último paso',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: context.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cuéntanos cómo vas a usar Renti para mostrarte las '
                  'funciones correctas.',
                  style: TextStyle(color: context.muted, fontSize: 15, height: 1.4),
                ),
                RentiTextField(
                  label: 'Nombre completo',
                  hint: 'Ej. María López',
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.nombreCompleto,
                  enabled: !_cargando,
                ),
                const FieldLabel('Quiero usar Renti como'),
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
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Continuar',
                  loading: _cargando,
                  onPressed: _continuar,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _cargando ? null : () => AppRoutes.cerrarSesion(context),
                    child: Text(
                      'Cancelar y cerrar sesión',
                      style: TextStyle(
                          color: context.muted, fontWeight: FontWeight.w700),
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

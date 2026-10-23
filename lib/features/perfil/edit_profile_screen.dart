import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';

/// Editar nombre, teléfono y universidad. El correo y el rol no se pueden
/// cambiar desde aquí (el rol lo protegen además las reglas de Firestore).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: appState.userName);
  late final _telefono =
      TextEditingController(text: appState.user?.telefono ?? '');
  late String? _universidad =
      appState.university.isEmpty ? null : appState.university;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);
    final error = await appState.actualizarPerfil(
      nombre: _nombre.text,
      telefono: _telefono.text,
      universidad: _universidad ?? '',
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      showSnack(context, error);
      return;
    }
    Navigator.of(context).pop();
    showSnack(context, 'Perfil actualizado');
  }

  @override
  Widget build(BuildContext context) {
    final pideUniversidad = !appState.isAdmin;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                RentiTheme.pad, 14, RentiTheme.pad, 24),
            children: [
              const ScreenHeader(title: 'Editar perfil'),
              const SizedBox(height: 10),
              RentiTextField(
                label: 'Nombre completo',
                hint: 'Tu nombre',
                controller: _nombre,
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                validator: Validators.nombreCompleto,
              ),
              const SizedBox(height: 4),
              RentiTextField(
                label: 'Teléfono (opcional)',
                hint: '10 dígitos',
                controller: _telefono,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.telefonoOpcional,
              ),
              if (pideUniversidad) ...[
                const SizedBox(height: 4),
                SelectField(
                  label: 'Universidad',
                  hint: 'Selecciona tu universidad',
                  value: _universidad,
                  options: Catalogos.universidades,
                  onChanged: (v) => setState(() => _universidad = v),
                ),
              ],
              const FieldLabel('Correo'),
              Text(appState.userEmail,
                  style: TextStyle(color: context.muted, fontSize: 16)),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Guardar cambios',
                loading: _guardando,
                onPressed: _guardando ? null : _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

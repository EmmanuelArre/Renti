import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/core/widgets/form_widgets.dart';

/// Formulario mínimo con los mismos validadores del registro.
class _Formulario extends StatefulWidget {
  const _Formulario();
  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _form = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmar = TextEditingController();
  bool enviado = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Form(
          key: _form,
          child: ListView(children: [
            RentiTextField(
                hint: 'Correo',
                controller: _correo,
                validator: Validators.correo),
            RentiTextField(
                hint: 'Contraseña',
                controller: _clave,
                obscure: true,
                validator: Validators.contrasena),
            RentiTextField(
                hint: 'Confirmar',
                controller: _confirmar,
                obscure: true,
                validator: (v) =>
                    Validators.confirmarContrasena(v, _clave.text)),
            TextButton(
              onPressed: () {
                if (_form.currentState!.validate()) {
                  setState(() => enviado = true);
                }
              },
              child: const Text('Enviar'),
            ),
            if (enviado) const Text('OK'),
          ]),
        ),
      );
}

void main() {
  Widget app() => MaterialApp(theme: RentiTheme.light(), home: const _Formulario());

  testWidgets('muestra errores si el formulario está vacío', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Enviar'));
    await tester.pump();

    expect(find.text('El correo electrónico es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
    expect(find.text('OK'), findsNothing);
  });

  testWidgets('detecta contraseñas que no coinciden', (tester) async {
    await tester.pumpWidget(app());
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'alumno@utng.edu.mx');
    await tester.enterText(campos.at(1), 'Abcdef12');
    await tester.enterText(campos.at(2), 'Abcdef13');
    await tester.tap(find.text('Enviar'));
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(find.text('OK'), findsNothing);
  });

  testWidgets('envía cuando todo es válido', (tester) async {
    await tester.pumpWidget(app());
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'alumno@utng.edu.mx');
    await tester.enterText(campos.at(1), 'Abcdef12');
    await tester.enterText(campos.at(2), 'Abcdef12');
    await tester.tap(find.text('Enviar'));
    await tester.pump();

    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('el campo de contraseña se puede mostrar y ocultar', (tester) async {
    await tester.pumpWidget(app());
    expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
    await tester.pump();
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });
}

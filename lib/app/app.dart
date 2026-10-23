import 'package:flutter/material.dart';

import 'package:renti/app/routes.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';

class RentiApp extends StatelessWidget {
  const RentiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => MaterialApp(
        title: 'Renti',
        debugShowCheckedModeBanner: false,
        theme: RentiTheme.light(),
        darkTheme: RentiTheme.dark(),
        themeMode: appState.themeMode,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

/// Pantalla que se muestra si Firebase no pudo iniciar (falta
/// `google-services.json`). Evita un cierre inesperado y explica qué hacer.
class FirebaseSetupErrorApp extends StatelessWidget {
  final Object error;
  const FirebaseSetupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: RentiTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(RentiTheme.pad),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.settings_suggest_rounded,
                    size: 64, color: RentiColors.orange),
                const SizedBox(height: 20),
                const Text(
                  'Falta configurar Firebase',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Descarga el archivo google-services.json de tu proyecto de '
                  'Firebase, colócalo en android/app/ y vuelve a ejecutar la '
                  'app. Los pasos completos están en README_CONFIGURACION.md.',
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 20),
                Text(
                  '$error',
                  style: const TextStyle(fontSize: 12, color: RentiColors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

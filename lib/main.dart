import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:renti/app/app.dart';
import 'package:renti/core/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  Object? firebaseError;
  try {
    // En Android lee la configuración de android/app/google-services.json.
    await Firebase.initializeApp();
  } catch (e) {
    firebaseError = e;
  }

  await appState.cargarPreferencias();
  runApp(
    firebaseError == null
        ? const RentiApp()
        : FirebaseSetupErrorApp(error: firebaseError),
  );
}

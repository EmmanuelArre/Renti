import 'package:flutter/material.dart';

import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/renti_logo.dart';
import 'package:renti/app/routes.dart';

/// 02 · Bienvenida
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg == 'suspendida') {
        showSnack(context,
            'Tu cuenta está suspendida. Contacta a soporte de Renti.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: RentiTheme.pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              Row(
                children: [
                  const RentiAppIcon(size: 38),
                  const SizedBox(width: 10),
                  Text(
                    'Renti',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              AspectRatio(
                aspectRatio: 342 / 270,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [RentiColors.blue, RentiColors.orange],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: const Alignment(-0.35, -0.15),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 50,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: const Alignment(-0.05, 0.55),
                        child: Container(
                          width: 26,
                          height: 34,
                          decoration: BoxDecoration(
                            color: RentiColors.yellow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Encuentra tu próximo espacio',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: context.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Rentas pensadas para estudiantes.',
                  style: TextStyle(fontSize: 16, color: context.muted),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Comenzar',
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.register),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Ya tengo una cuenta',
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.login),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

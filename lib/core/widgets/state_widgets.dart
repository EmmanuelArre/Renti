import 'package:flutter/material.dart';

import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';

/// Indicador de carga centrado.
class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: RentiColors.blue),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: TextStyle(color: context.muted)),
            ],
          ],
        ),
      );
}

/// Estado vacío con icono, texto y (opcional) un botón.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: context.card,
                  shape: BoxShape.circle,
                  boxShadow: softShadow(0.1),
                ),
                child: Icon(icon, size: 50, color: RentiColors.orange),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  color: context.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.muted, fontSize: 15),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: 252,
                  child: PrimaryButton(label: actionLabel!, onPressed: onAction),
                ),
              ],
            ],
          ),
        ),
      );
}

/// Error con botón para reintentar.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => EmptyView(
        icon: Icons.cloud_off_rounded,
        title: 'Algo salió mal',
        subtitle: message,
        actionLabel: onRetry == null ? null : 'Reintentar',
        onAction: onRetry,
      );
}

/// Franja que avisa que se están mostrando datos guardados en el teléfono.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: RentiColors.yellow,
        child: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, size: 18, color: RentiColors.ink),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sin conexión: mostrando datos guardados en tu teléfono.',
                style: TextStyle(
                  color: RentiColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Diálogo de confirmación. Devuelve `true` si la persona acepta.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String aceptar = 'Confirmar',
  bool peligroso = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            aceptar,
            style: TextStyle(
              color: peligroso ? Colors.redAccent : RentiColors.blue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Pestañas "píldora" para filtrar listas (Pendientes, Aprobadas…).
class FilterPills extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const FilterPills({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final o in options) ...[
              GestureDetector(
                onTap: () => onChanged(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: o == selected ? RentiColors.blue : context.card,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: o == selected ? RentiColors.blue : context.line,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    o,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: o == selected ? Colors.white : context.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      );
}

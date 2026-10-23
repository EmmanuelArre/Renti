import 'package:flutter/material.dart';

import 'package:renti/core/theme/app_theme.dart';

/// Botón naranja principal.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color color;
  final bool shadow;

  /// Muestra un indicador de carga y deshabilita el botón.
  final bool loading;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.color = RentiColors.orange,
    this.shadow = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: shadow && enabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón blanco con borde (secundario).
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color? textColor;
  final Color? borderColor;
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor ?? context.line,
          width: borderColor != null ? 1.8 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor ?? context.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón circular con flecha de regreso.
class CircleBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? background;
  const CircleBackButton({super.key, this.onPressed, this.background});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background ?? context.card,
          shape: BoxShape.circle,
          boxShadow: softShadow(0.12),
        ),
        child: Icon(Icons.chevron_left_rounded, color: context.ink, size: 28),
      ),
    );
  }
}

/// Botón circular con corazón (favoritos).
class HeartButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final double size;
  const HeartButton({
    super.key,
    required this.active,
    required this.onTap,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(
          active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: RentiColors.orange,
          size: size * 0.55,
        ),
      ),
    );
  }
}

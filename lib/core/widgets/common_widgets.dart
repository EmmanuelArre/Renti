import 'package:flutter/material.dart';

import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';

/// Cabecera con flecha atrás a la izquierda y título centrado.
class ScreenHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  const ScreenHeader({super.key, required this.title, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBack) const Align(alignment: Alignment.centerLeft, child: CircleBackButton()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: context.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título grande alineado a la izquierda (pantallas con menú inferior).
class BigTitle extends StatelessWidget {
  final String text;
  const BigTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: context.ink,
        ),
      );
}

class Avatar extends StatelessWidget {
  final String initials;
  final double size;
  final bool highlighted;
  const Avatar(
    this.initials, {
    super.key,
    this.size = 48,
    this.highlighted = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlighted ? RentiColors.blue : context.line,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: highlighted ? Colors.white : context.ink,
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const StatusBadge(
    this.text, {
    super.key,
    this.color = RentiColors.green,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Tarjeta blanca redondeada con sombra suave.
class WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Border? border;
  final VoidCallback? onTap;
  const WhiteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(24),
        border: border,
        boxShadow: softShadow(),
      ),
      child: child,
    );
    return onTap == null ? box : GestureDetector(onTap: onTap, child: box);
  }
}

/// Fila "etiqueta ……… valor".
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const DetailRow(this.label, this.value, {super.key, this.bold = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.muted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: RentiColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
}

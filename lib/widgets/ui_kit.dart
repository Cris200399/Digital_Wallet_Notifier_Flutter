import 'dart:ui';
import 'package:flutter/material.dart';

/// Paleta de acento reutilizable.
class AppColors {
  static const navy = Color(0xFF14416B);
  static const teal = Color(0xFF2EA6A0);
  static const ink = Color(0xFF17171A);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFDC2626);
  static const amber = Color(0xFFD97706);
}

/// Tarjeta con profundidad: fondo claro, borde sutil y sombra suave en capas.
/// Da la sensación de elevación sin ser pesada.
class DepthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Gradient? gradient;
  final Color? color;

  const DepthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Colors.white) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.18), // más visible
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -10,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Panel con efecto glassmorphism: fondo translúcido y desenfoque.
/// Útil para superponer sobre gradientes de color.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double blur;
  final double opacity;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.blur = 18,
    this.opacity = 0.18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Métrica compacta para las estadísticas: valor grande + etiqueta.
class StatTile extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final IconData icono;
  final Color color;

  const StatTile({
    super.key,
    required this.valor,
    required this.etiqueta,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

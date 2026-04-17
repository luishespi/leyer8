import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

/// Tarjeta tonal de Leyer8.
///
/// Se apoya en el sistema de capas para separarse del fondo — nunca en bordes.
/// Tres niveles de énfasis:
/// - [TonalCardLevel.subtle]  → contenedor neutral sobre fondo surface.
/// - [TonalCardLevel.raised]  → blanco flotante, capta atención inmediata.
/// - [TonalCardLevel.sunken]  → surface_container_high, zonas secundarias.
///
/// Por defecto usa padding `lg` (16px). Las tarjetas principales de pantalla
/// deben usar al menos `xl` (24px).
enum TonalCardLevel { subtle, raised, sunken }

class TonalCard extends StatelessWidget {
  final Widget child;
  final TonalCardLevel level;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final VoidCallback? onTap;
  final bool elevated;

  const TonalCard({
    super.key,
    required this.child,
    this.level = TonalCardLevel.subtle,
    this.padding,
    this.radius,
    this.onTap,
    this.elevated = false,
  });

  Color get _background {
    switch (level) {
      case TonalCardLevel.subtle:
        return AppColors.surfaceContainerLow;
      case TonalCardLevel.raised:
        return AppColors.surfaceContainerLowest;
      case TonalCardLevel.sunken:
        return AppColors.surfaceContainerHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius ?? AppRadii.xl);

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: _background,
        borderRadius: borderRadius,
        boxShadow: elevated ? AppShadows.soft : AppShadows.none,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: content,
      ),
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: AppColors.primary.withValues(alpha: 0.04),
        highlightColor: AppColors.primary.withValues(alpha: 0.02),
        child: decorated,
      ),
    );
  }
}
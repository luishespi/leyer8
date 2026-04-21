import 'package:flutter/material.dart';
import 'package:leyer8/core/theme/app_colors.dart';
import 'package:leyer8/core/theme/app_radii.dart';
import 'package:leyer8/core/theme/app_spacing.dart';
import 'package:leyer8/core/theme/app_typography.dart';



/// Estado visual de un paso en el onboarding.
enum StepStatus { active, pending, completed }

/// Tarjeta de paso numerado para el onboarding de configuración.
///
/// Sigue el wireframe de `configuracion_inicial.webp`:
///   - Activo: badge navy con número blanco, texto prominente.
///   - Pendiente: badge gris claro, texto en onSurfaceVariant.
///   - Completado: badge verde con check.
///
/// No usa bordes de 1px — la separación entre pasos se logra con
/// espaciado y cambios tonales (DESIGN.md §2).
class StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final StepStatus status;
  final Widget? extra;

  const StepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
    this.status = StepStatus.pending,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == StepStatus.active;
    final isCompleted = status == StepStatus.completed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge numerado.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.secondary
                  : isActive
                      ? AppColors.primary
                      : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.onSecondary,
                      size: 20,
                    )
                  : Text(
                      '$stepNumber',
                      style: AppTypography.titleMedium.copyWith(
                        color: isActive
                            ? AppColors.onPrimary
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Contenido del paso.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  title,
                  style: isActive
                      ? AppTypography.titleLarge
                      : AppTypography.titleLarge.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: isActive
                      ? AppTypography.bodyMedium
                      : AppTypography.bodySmall,
                ),
                if (extra != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  extra!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de texto monoespaciado para mostrar IPs, URLs, etc.
///
/// Fondo tonal, sin bordes, esquinas redondeadas.
class CodeChip extends StatelessWidget {
  final String text;

  const CodeChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: AppRadii.radiusMd,
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/tonal_card.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/provisioning_controller.dart';

/// Pantalla de provisión del perfil NextDNS.
///
/// Se muestra automáticamente después de verificar el correo.
/// Llama al backend para crear el perfil NextDNS y espera a que
/// Firestore se actualice. El AuthGate detecta el cambio y
/// reenruta a la siguiente pantalla.
///
/// Tono editorial: calmado, sin tecnicismos. "Preparando tu escudo…"
class ProvisioningScreen extends ConsumerStatefulWidget {
  const ProvisioningScreen({super.key});

  @override
  ConsumerState<ProvisioningScreen> createState() =>
      _ProvisioningScreenState();
}

class _ProvisioningScreenState extends ConsumerState<ProvisioningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Disparar la provisión al entrar a la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startProvisioning());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startProvisioning() async {
    if (_started) return;
    _started = true;

    final ok = await ref
        .read(provisioningControllerProvider.notifier)
        .provision();

    if (!mounted) return;

    if (ok) {
      // Forzar re-lectura del documento de usuario. El backend ya escribió
      // en Firestore, pero el stream local puede tardar un instante.
      ref.invalidate(userDocProvider);
    } else {
      // Permitir reintento.
      _started = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provisioningControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Center(
            child: state.errorMessage != null
                ? _buildError(state.errorMessage!)
                : _buildLoading(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Escudo animado con pulso suave.
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.08);
            final opacity = 0.6 + (_pulseController.value * 0.4);
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: child,
              ),
            );
          },
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.secondary,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Preparando tu escudo…',
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Estamos configurando la protección de tu red.\nEsto solo toma unos segundos.',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(
              AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Algo no salió bien',
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          TonalCard(
            level: TonalCardLevel.raised,
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Intentar de nuevo',
            trailing: const Icon(Icons.refresh_rounded),
            onPressed: _startProvisioning,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            child: Text(
              'Cerrar sesión',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
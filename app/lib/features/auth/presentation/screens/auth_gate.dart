import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leyer8/features/auth/presentation/screens/router_setup_screen.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../onboarding/application/provisioning_controller.dart';
import '../../../onboarding/presentation/screens/provisioning_screen.dart';
import '../../application/auth_controller.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

/// Guard raíz de la app. Decide qué pantalla mostrar según el estado
/// de autenticación, provisión y onboarding.
///
/// Flujo:
///   sin sesión                              → LoginScreen
///   sesión sin verificar                    → EmailVerificationScreen
///   sesión verificada, sin perfil NextDNS   → ProvisioningScreen
///   sesión verificada, perfil listo, onboarding pendiente → RouterSetupScreen
///   sesión verificada, perfil listo, onboarding completo  → DashboardPlaceholder
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _SplashLoading(),
      error: (_, __) => const LoginScreen(),
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        if (!user.emailVerified) {
          return const EmailVerificationScreen();
        }

        // Usuario verificado — revisar estado en Firestore.
        return const _PostVerificationGate();
      },
    );
  }
}

/// Gate secundario que revisa el documento de Firestore para decidir
/// si mostrar provisión, router setup, o dashboard.
class _PostVerificationGate extends ConsumerWidget {
  const _PostVerificationGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(userDocProvider);

    return userDocAsync.when(
      loading: () => const _SplashLoading(),
      error: (_, __) => const ProvisioningScreen(),
      data: (userData) {
        if (userData == null) {
          return const ProvisioningScreen();
        }

        final profileId = userData['nextdnsProfileId'] as String?;
        final status = userData['provisioningStatus'] as String?;
        final onboardingCompleted =
            userData['onboardingCompleted'] as bool? ?? false;

        // Sin perfil o provisión incompleta → provisionar.
        if (profileId == null || status != 'completed') {
          return const ProvisioningScreen();
        }

        // Perfil listo, onboarding pendiente → configurar router.
        if (!onboardingCompleted) {
          return const RouterSetupScreen();
        }

        // Todo completo → dashboard.
        return const _DashboardPlaceholder();
      },
    );
  }
}

// ============================================================
// Splash mientras carga
// ============================================================

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Dashboard placeholder — se reemplaza en Fase 2
// ============================================================

class _DashboardPlaceholder extends ConsumerWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final userDoc = ref.watch(userDocProvider).value;
    final profileId = userDoc?['nextdnsProfileId'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: AppColors.secondary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Escudo activo',
                  style: AppTypography.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  user?.email ?? '',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Perfil: $profileId',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Tu red está protegida.\nEl panel de control llega en Fase 2.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                TextButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../onboarding/application/provisioning_controller.dart';
import '../../../onboarding/presentation/screens/provisioning_screen.dart';
import '../../application/auth_controller.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

/// Guard raíz de la app. Decide qué pantalla mostrar según el estado
/// de autenticación y provisión.
///
/// Flujo:
///   sin sesión              → LoginScreen
///   sesión sin verificar    → EmailVerificationScreen
///   sesión verificada, sin perfil NextDNS → ProvisioningScreen
///   sesión verificada + perfil listo      → _DashboardPlaceholder
///
/// Escucha reactivamente [authStateProvider] y [userDocProvider],
/// por lo que cualquier cambio reenruta automáticamente.
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

        // Usuario verificado — revisar si ya tiene perfil NextDNS.
        return _PostVerificationGate();
      },
    );
  }
}

/// Gate secundario que revisa el documento de Firestore para decidir
/// si mostrar la pantalla de provisión o el dashboard.
///
/// Separado del AuthGate principal para que el StreamProvider de
/// userDoc solo se active cuando hay un usuario verificado.
class _PostVerificationGate extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(userDocProvider);

    return userDocAsync.when(
      loading: () => const _SplashLoading(),
      error: (_, __) => const ProvisioningScreen(),
      data: (userData) {
        if (userData == null) {
          // Doc no existe todavía — puede pasar si Firestore aún no
          // replicó tras el registro. Mostrar provisioning que reintenta.
          return const ProvisioningScreen();
        }

        final profileId = userData['nextdnsProfileId'] as String?;
        final status = userData['provisioningStatus'] as String?;

        if (profileId != null && status == 'completed') {
          // Perfil listo → dashboard (Día 5 lo reemplaza por RouterSetup).
          return const _DashboardPlaceholder();
        }

        // Sin perfil o provisión incompleta → provisionar.
        return const ProvisioningScreen();
      },
    );
  }
}

// ============================================================
// Splash mientras Firebase inicializa la sesión
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
// Placeholder del dashboard — se reemplaza en Día 5
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
                  decoration: BoxDecoration(
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
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Siguiente paso: configurar el DNS\nen tu router (Día 5).',
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
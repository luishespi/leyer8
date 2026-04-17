import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/auth_controller.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

/// Guard raíz de la app. Decide qué pantalla mostrar según el estado
/// de autenticación.
///
/// Flujo:
///   sin sesión            → LoginScreen
///   sesión sin verificar  → EmailVerificationScreen
///   sesión + verificada   → _AuthenticatedPlaceholder (Día 4-5 lo reemplaza)
///
/// Escucha reactivamente [authStateProvider], por lo que cualquier cambio
/// (login, logout, verificación) reenruta automáticamente sin `Navigator.push`.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authStateProvider);

  // LOG TEMPORAL - quitar después
  print('[AuthGate] state: $authState');
  authState.whenData((user) {
    print('[AuthGate] user: ${user?.email}, verified: ${user?.emailVerified}');
  });

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
      return const _AuthenticatedPlaceholder();
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
// Placeholder temporal post-auth
// ============================================================
// Este placeholder se reemplaza en Día 4-5 por la pantalla
// "Configura tu Router". No invertir tiempo en estilizarlo.

class _AuthenticatedPlaceholder extends ConsumerWidget {
  const _AuthenticatedPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sesión iniciada',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
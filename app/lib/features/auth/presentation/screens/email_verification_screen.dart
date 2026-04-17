import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/screen_scaffold.dart';
import '../../../../shared/widgets/tonal_card.dart';
import '../../application/auth_controller.dart';

/// Pantalla intermedia para usuarios registrados que aún no han verificado
/// su correo.
///
/// Comportamiento:
///   - Polling cada 4s: consulta Firebase para detectar si el correo fue
///     verificado (al hacer click en el enlace desde otro dispositivo,
///     Firebase no notifica al cliente — hay que preguntar).
///   - Botón "Ya verifiqué" — chequeo manual inmediato.
///   - Botón "Reenviar correo" — con cooldown de 30s para evitar abuso.
///   - Link "Usar otra cuenta" — cierra sesión y regresa al login.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _pollingTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _checkingNow = false;

  static const _pollInterval = Duration(seconds: 4);
  static const _resendCooldown = 30;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollInterval, (_) => _checkVerified());
  }

  Future<void> _checkVerified({bool showFeedback = false}) async {
    if (_checkingNow) return;
    _checkingNow = true;
    try {
      final verified =
          await ref.read(authControllerProvider.notifier).checkEmailVerified();
      if (!mounted) return;

      if (verified) {
        _pollingTimer?.cancel();
        // authStateChanges() de Firebase no emite cuando solo cambia
        // emailVerified tras un reload() — solo emite en login/logout.
        // Invalidamos el provider: Riverpod lo re-suscribe al stream y el
        // primer valor emitido es el currentUser actualizado (con
        // emailVerified=true), lo que hace que el AuthGate reconstruya y
        // reenrute al siguiente paso del flujo.
        ref.invalidate(authStateProvider);
      } else if (showFeedback) {
        _showSnack(
          'Aún no detectamos la verificación. Intenta de nuevo en un momento.',
          isError: false,
        );
      }
    } finally {
      _checkingNow = false;
    }
  }

  Future<void> _resend() async {
    if (_cooldownSeconds > 0) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .resendVerification();
    if (!mounted) return;

    if (ok) {
      _showSnack('Te reenviamos el correo de verificación.', isError: false);
      _startCooldown();
    } else {
      final err = ref.read(authControllerProvider).errorMessage;
      if (err != null) _showSnack(err, isError: true);
    }
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = _resendCooldown);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) timer.cancel();
      });
    });
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onPrimary),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final userEmail =
        ref.watch(authStateProvider).value?.email ?? 'tu correo';

    return ScreenScaffold(
      title: 'Verifica tu correo',
      subtitle:
          'Te enviamos un enlace de confirmación. Ábrelo para activar tu escudo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TonalCard(
            level: TonalCardLevel.raised,
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_rounded,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Correo enviado a',
                            style: AppTypography.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: AppTypography.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Revisa tu bandeja de entrada. Si no lo encuentras, mira en spam '
                  'o promociones. Detectaremos automáticamente cuando verifiques.',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Ya verifiqué mi correo',
            trailing: const Icon(Icons.arrow_forward_rounded),
            onPressed: auth.isLoading
                ? null
                : () => _checkVerified(showFeedback: true),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: (auth.isLoading || _cooldownSeconds > 0) ? null : _resend,
            child: Text(
              _cooldownSeconds > 0
                  ? 'Reenviar correo en ${_cooldownSeconds}s'
                  : 'Reenviar correo',
              style: AppTypography.labelMedium.copyWith(
                color: _cooldownSeconds > 0
                    ? AppColors.onSurfaceVariant
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextButton(
            onPressed: auth.isLoading
                ? null
                : () =>
                    ref.read(authControllerProvider.notifier).signOut(),
            child: Text(
              'Usar otra cuenta',
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
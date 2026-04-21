import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leyer8/features/auth/presentation/widgets/step_card.dart';
import 'package:leyer8/features/onboarding/application/provisioning_controller.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/tonal_card.dart';
import '../../../auth/application/auth_controller.dart';


/// Provider que lee el documento de nextdns_profiles para obtener las IPs.
final profileDnsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final userDoc = ref.watch(userDocProvider).value;
  if (userDoc == null) return null;

  final profileId = userDoc['nextdnsProfileId'] as String?;
  if (profileId == null) return null;

  final snap = await FirebaseFirestore.instance
      .collection('nextdns_profiles')
      .doc(profileId)
      .get();

  return snap.data();
});

/// Pantalla de configuración del router — Día 5.
///
/// Guía al usuario en 3 pasos para cambiar el DNS de su router
/// al perfil NextDNS que se creó automáticamente. Muestra las IPs
/// reales del perfil del usuario, no genéricas.
///
/// Referencia: `configuracion_inicial.webp`
class RouterSetupScreen extends ConsumerStatefulWidget {
  const RouterSetupScreen({super.key});

  @override
  ConsumerState<RouterSetupScreen> createState() => _RouterSetupScreenState();
}

class _RouterSetupScreenState extends ConsumerState<RouterSetupScreen> {
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    // Marcar onboarding como completado.
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'onboardingCompleted': true});
    }
    // El userDocProvider detecta el cambio y AuthGate reenruta.
  }

  Future<void> _skip() async {
    // Omitir — entra al dashboard pero no marca como completado.
    // Para Fase 1, marcamos como completado de todas formas para
    // no bloquear al usuario en un loop.
    await _complete();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copiado: $text',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onPrimary),
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  StepStatus _statusFor(int step) {
    if (step < _currentStep) return StepStatus.completed;
    if (step == _currentStep) return StepStatus.active;
    return StepStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileDnsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: indicador de pasos + Omitir.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  // Indicadores de paso.
                  Row(
                    children: List.generate(3, (i) {
                      final isActive = i == _currentStep;
                      return Container(
                        width: isActive ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Omitir',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido scrollable.
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    // Icono del router.
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.router_rounded,
                        color: AppColors.onPrimary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Configura tu Router',
                      style: AppTypography.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Para proteger todos los dispositivos de tu hogar, '
                      'cambiaremos la configuración DNS de tu router en '
                      '3 sencillos pasos.',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Tarjeta con los 3 pasos.
                    TonalCard(
                      level: TonalCardLevel.raised,
                      elevated: true,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          StepCard(
                            stepNumber: 1,
                            title: 'Accede a tu router',
                            description:
                                'Abre tu navegador y escribe la dirección de tu router.',
                            status: _statusFor(0),
                            extra: GestureDetector(
                              onTap: () =>
                                  _copyToClipboard('192.168.1.1'),
                              child: const CodeChip(text: '192.168.1.1'),
                            ),
                          ),
                          StepCard(
                            stepNumber: 2,
                            title: 'Inicia sesión',
                            description:
                                'Usa la contraseña que viene detrás de tu equipo. '
                                'Generalmente es "admin" o está en una etiqueta.',
                            status: _statusFor(1),
                          ),
                          profileAsync.when(
                            loading: () => StepCard(
                              stepNumber: 3,
                              title: 'Cambia el DNS',
                              description:
                                  'Cargando tus servidores DNS…',
                              status: _statusFor(2),
                            ),
                            error: (_, __) => StepCard(
                              stepNumber: 3,
                              title: 'Cambia el DNS',
                              description:
                                  'No pudimos cargar tus IPs. Intenta de nuevo.',
                              status: _statusFor(2),
                            ),
                            data: (profile) {
                              final ipv4 = profile?['dnsIpv4'] as List?;
                              final dns1 =
                                  ipv4 != null && ipv4.isNotEmpty
                                      ? ipv4[0].toString()
                                      : '45.90.28.90';
                              final dns2 =
                                  ipv4 != null && ipv4.length > 1
                                      ? ipv4[1].toString()
                                      : '45.90.30.90';

                              return StepCard(
                                stepNumber: 3,
                                title: 'Cambia el DNS',
                                description:
                                    'En la sección de DNS de tu router, '
                                    'reemplaza los servidores por estos:',
                                status: _statusFor(2),
                                extra: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () =>
                                          _copyToClipboard(dns1),
                                      child: Row(
                                        children: [
                                          Text(
                                            'DNS 1:  ',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          CodeChip(text: dns1),
                                          const SizedBox(
                                              width: AppSpacing.sm),
                                          Icon(
                                            Icons.copy_rounded,
                                            size: 16,
                                            color:
                                                AppColors.onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                        height: AppSpacing.sm),
                                    GestureDetector(
                                      onTap: () =>
                                          _copyToClipboard(dns2),
                                      child: Row(
                                        children: [
                                          Text(
                                            'DNS 2: ',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          CodeChip(text: dns2),
                                          const SizedBox(
                                              width: AppSpacing.sm),
                                          Icon(
                                            Icons.copy_rounded,
                                            size: 16,
                                            color:
                                                AppColors.onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // Botón inferior fijo.
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: AppSpacing.xl,
                top: AppSpacing.md,
              ),
              child: PrimaryButton(
                label: _currentStep < 2
                    ? 'Siguiente paso →'
                    : 'Listo, ya configuré mi router',
                trailing: _currentStep < 2
                    ? const Icon(Icons.arrow_forward_rounded)
                    : const Icon(Icons.check_rounded),
                onPressed: _nextStep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
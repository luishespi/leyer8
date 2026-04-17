import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/validators/form_validators.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/screen_scaffold.dart';
import '../../../../shared/widgets/text_field_sentinel.dart';
import '../../../../shared/widgets/tonal_card.dart';
import '../../application/auth_controller.dart';

/// Pantalla de recuperación de contraseña.
///
/// Una vez enviado el correo, la pantalla muestra un estado de confirmación
/// calmado con opción de reenviar si el correo no llegó.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text);

    if (!mounted) return;

    if (ok) {
      setState(() => _sent = true);
    } else {
      final err = ref.read(authControllerProvider).errorMessage;
      if (err != null) _showSnack(err);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onPrimary),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return ScreenScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        color: AppColors.onSurface,
        onPressed: auth.isLoading ? null : () => Navigator.of(context).pop(),
      ),
      title: _sent ? 'Correo enviado' : 'Recupera tu acceso',
      subtitle: _sent
          ? 'Revisa tu bandeja de entrada para continuar.'
          : 'Te enviaremos un enlace para restablecer tu contraseña.',
      child: _sent ? _buildSentState() : _buildForm(auth.isLoading),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFieldSentinel(
            label: 'Correo electrónico',
            hint: 'tu@correo.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: FormValidators.email,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Enviar enlace',
            isLoading: isLoading,
            onPressed: isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSentState() {
    return Column(
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
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _emailController.text.trim(),
                      style: AppTypography.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Abre el enlace que te enviamos para elegir una nueva contraseña. '
                'Si no lo ves, revisa tu carpeta de spam.',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Volver al inicio',
          trailing: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => setState(() => _sent = false),
          child: Text(
            'No recibí el correo',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
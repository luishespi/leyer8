import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/validators/form_validators.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/screen_scaffold.dart';
import '../../../../shared/widgets/text_field_sentinel.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_link.dart';

/// Pantalla de registro.
///
/// Al completarse exitosamente, el AuthRepository:
///   1. Crea la cuenta en Firebase Auth.
///   2. Escribe el documento users/{uid} en Firestore.
///   3. Envía el correo de verificación.
///
/// El AuthGate detecta el cambio de estado y enruta automáticamente
/// a EmailVerificationScreen.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(authControllerProvider.notifier).register(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );

    if (!mounted) return;

    if (!ok) {
      final err = ref.read(authControllerProvider).errorMessage;
      if (err != null) _showSnack(err, isError: true);
      return;
    }

    // Éxito: cerramos las pantallas pusheadas (RegisterScreen y cualquier
    // otra intermedia) para que el AuthGate pueda renderizar
    // EmailVerificationScreen. El AuthGate solo reenruta lo que él mismo
    // renderiza — no puede destapar rutas pusheadas encima suyo.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.bodyMedium.copyWith(
          color: AppColors.onPrimary,
        )),
        backgroundColor: isError ? AppColors.error : AppColors.secondary,
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
      title: 'Crea tu cuenta',
      subtitle: 'Configuramos tu escudo digital en menos de 5 minutos.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFieldSentinel(
              label: 'Nombre',
              hint: 'Así te llamaremos en la app',
              controller: _nameController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              validator: FormValidators.name,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFieldSentinel(
              label: 'Correo electrónico',
              hint: 'tu@correo.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
              validator: FormValidators.email,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFieldSentinel(
              label: 'Contraseña',
              hint: 'Mínimo 8 caracteres',
              helperText: 'Combina letras y números.',
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: FormValidators.password,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFieldSentinel(
              label: 'Confirma tu contraseña',
              hint: 'Repite la contraseña',
              controller: _confirmController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              validator: (value) => FormValidators.passwordConfirmation(
                value,
                _passwordController.text,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () => setState(
                  () => _obscureConfirm = !_obscureConfirm,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Al registrarte aceptas nuestros Términos de Uso y Política de Privacidad.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Crear cuenta',
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AuthLink(
              leadingText: '¿Ya tienes cuenta?',
              actionText: 'Inicia sesión',
              onPressed: auth.isLoading
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
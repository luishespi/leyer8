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
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Pantalla de inicio de sesión.
///
/// Flujo: el AuthGate observa el estado de auth, así que al tener éxito
/// no hace falta `Navigator.push` — el gate reenruta automáticamente.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (!ok) {
      final err = ref.read(authControllerProvider).errorMessage;
      if (err != null) _showSnack(err, isError: true);
    }
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
      title: 'Bienvenido',
      subtitle: 'Inicia sesión para continuar protegiendo tu hogar.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFieldSentinel(
              label: 'Correo electrónico',
              hint: 'tu@correo.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: FormValidators.email,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFieldSentinel(
              label: 'Contraseña',
              hint: 'Tu contraseña',
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: FormValidators.required,
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
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Iniciar sesión',
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AuthLink(
              leadingText: '¿No tienes cuenta?',
              actionText: 'Regístrate',
              onPressed: auth.isLoading
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
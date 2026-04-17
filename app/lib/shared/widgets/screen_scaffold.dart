import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Layout base de las pantallas de Leyer8.
///
/// Aplica el respiro editorial (padding horizontal `xl` = 24px) y gestiona
/// SafeArea de forma consistente. Acepta un header opcional (título + subtítulo)
/// que sigue la jerarquía tipográfica del sistema, o un encabezado custom.
///
/// Para pantallas simples:
/// ```dart
/// ScreenScaffold(
///   title: 'Horarios',
///   subtitle: 'Configura ventanas de tiempo.',
///   child: ...,
/// )
/// ```
///
/// Para layouts que necesitan un footer fijo (ej. botón de acción principal):
/// ```dart
/// ScreenScaffold(
///   title: '...',
///   footer: PrimaryButton(...),
///   child: ...,
/// )
/// ```
class ScreenScaffold extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? customHeader;
  final Widget? footer;
  final Widget? leading;
  final List<Widget>? actions;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const ScreenScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.customHeader,
    this.footer,
    this.leading,
    this.actions,
    this.scrollable = true,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: AppSpacing.xl);

    final hasTopBar = leading != null || (actions != null && actions!.isNotEmpty);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTopBar) _TopBar(leading: leading, actions: actions),
        if (customHeader != null)
          customHeader!
        else if (title != null)
          _DefaultHeader(title: title!, subtitle: subtitle),
        child,
        const SizedBox(height: AppSpacing.xl),
      ],
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(padding: effectivePadding, child: content),
            ),
            if (footer != null)
              Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: AppSpacing.xl,
                  top: AppSpacing.md,
                ),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final Widget? leading;
  final List<Widget>? actions;

  const _TopBar({this.leading, this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      child: Row(
        children: [
          if (leading != null) leading!,
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class _DefaultHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _DefaultHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }
}
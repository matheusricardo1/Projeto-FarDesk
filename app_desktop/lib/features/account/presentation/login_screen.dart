import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/account.dart';
import 'session_view_model.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    final session = context.watch<SessionViewModel>();
    final pending = session.pendingSignIn;

    return ClipRect(
      child: Stack(
        children: [
          Positioned(top: rem(-120), right: rem(-100), child: _Glow(color: AppColors.brand, size: rem(340))),
          Positioned(bottom: rem(-140), left: rem(-100), child: _Glow(color: AppColors.brandAlt, size: rem(320))),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: rem(380)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 64),
                  SizedBox(height: rem(Space.xxl)),
                  Text('FarDesk', style: text.display.copyWith(fontSize: rem(28))),
                  SizedBox(height: rem(Space.sm)),
                  Text('Seus dispositivos, de qualquer lugar.', textAlign: TextAlign.center, style: text.body),
                  SizedBox(height: rem(Space.huge)),
                  AppButton(
                    label: 'Continuar com Google',
                    icon: Icons.g_mobiledata,
                    variant: AppButtonVariant.inverse,
                    size: AppButtonSize.large,
                    expand: true,
                    loading: pending == AuthProvider.google,
                    onPressed: pending == null ? () => session.signIn(AuthProvider.google) : null,
                  ),
                  SizedBox(height: rem(Space.md)),
                  AppButton(
                    label: 'Entrar com e-mail',
                    variant: AppButtonVariant.ghost,
                    loading: pending == AuthProvider.email,
                    onPressed: pending == null ? () => session.signIn(AuthProvider.email) : null,
                  ),
                  if (session.error != null) ...[
                    SizedBox(height: rem(Space.lg)),
                    const InlineNotice(text: 'Não foi possível entrar. Tente de novo.'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

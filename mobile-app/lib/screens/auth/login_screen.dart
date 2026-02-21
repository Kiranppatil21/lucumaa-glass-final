import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:formz/formz.dart';

import '../../core/routing/route_paths.dart';
import '../../providers/auth/login_form.dart';
import '../../widgets/app_text_input.dart';
import '../../widgets/primary_button.dart';
import '../../core/security/sensitive_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final form = ref.watch(loginFormProvider);
    final isSubmitting = form.submission == FormzSubmissionStatus.inProgress;

    return SensitiveScreen(
      child: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welcome', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'Email',
                    onChanged: (v) => ref.read(loginFormProvider.notifier).onUsernameChanged(v),
                    errorText: form.username.displayError,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AppTextInput(
                    label: 'Password',
                    obscureText: true,
                    onChanged: (v) => ref.read(loginFormProvider.notifier).onPasswordChanged(v),
                    errorText: form.password.displayError,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Login',
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : () => ref.read(loginFormProvider.notifier).submit(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(RoutePaths.forgotPassword),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


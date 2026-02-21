import 'package:formz/formz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_providers.dart';
import '../../core/di/providers.dart';
import '../../core/network/app_exception.dart';

class EmailInput extends FormzInput<String, String> {
  const EmailInput.pure() : super.pure('');
  const EmailInput.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Email is required';
    if (!v.contains('@')) return 'Enter a valid email';
    return null;
  }
}

class PasswordInput extends FormzInput<String, String> {
  const PasswordInput.pure() : super.pure('');
  const PasswordInput.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 4) return 'Password too short';
    return null;
  }
}

class LoginFormState {
  final EmailInput username;
  final PasswordInput password;
  final FormzSubmissionStatus submission;
  final String? error;

  const LoginFormState({
    required this.username,
    required this.password,
    required this.submission,
    this.error,
  });

  factory LoginFormState.initial() => const LoginFormState(
      username: EmailInput.pure(),
        password: PasswordInput.pure(),
        submission: FormzSubmissionStatus.initial,
      );

  bool get isValid => Formz.validate([username, password]);

  LoginFormState copyWith({
    EmailInput? username,
    PasswordInput? password,
    FormzSubmissionStatus? submission,
    String? error,
  }) {
    return LoginFormState(
      username: username ?? this.username,
      password: password ?? this.password,
      submission: submission ?? this.submission,
      error: error,
    );
  }
}

final loginFormProvider = StateNotifierProvider.autoDispose<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier(ref);
});

class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier(this._ref) : super(LoginFormState.initial());

  final Ref _ref;

  void onUsernameChanged(String value) {
    state = state.copyWith(username: EmailInput.dirty(value), error: null);
  }

  void onPasswordChanged(String value) {
    state = state.copyWith(password: PasswordInput.dirty(value), error: null);
  }

  Future<void> submit() async {
    final username = EmailInput.dirty(state.username.value);
    final password = PasswordInput.dirty(state.password.value);
    final isValid = Formz.validate([username, password]);
    state = state.copyWith(username: username, password: password);
    if (!isValid) return;

    state = state.copyWith(submission: FormzSubmissionStatus.inProgress, error: null);
    try {
      await _ref.read(authNotifierProvider.notifier).login(
            email: username.value.trim(),
            password: password.value,
          );
      state = state.copyWith(submission: FormzSubmissionStatus.success);
    } catch (e) {
      final ex = AppException.fromDio(e);
      _ref.read(snackbarServiceProvider).showMessage(ex.message);
      state = state.copyWith(submission: FormzSubmissionStatus.failure, error: ex.message);
    }
  }
}

import '../../models/auth_tokens.dart';
import '../../models/user.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final AuthTokens? tokens;
  final User? user;
  final String? errorMessage;

  const AuthState._({
    required this.status,
    this.tokens,
    this.user,
    this.errorMessage,
  });

  const AuthState.unknown() : this._(status: AuthStatus.unknown);
  const AuthState.unauthenticated([String? message])
      : this._(status: AuthStatus.unauthenticated, errorMessage: message);
  const AuthState.authenticated({required AuthTokens tokens, required User user})
      : this._(status: AuthStatus.authenticated, tokens: tokens, user: user);

  bool get isLoggedIn => status == AuthStatus.authenticated;
}

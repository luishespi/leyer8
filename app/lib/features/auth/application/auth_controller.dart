import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/auth_repository.dart';

/// Providers y controlador de autenticación (Riverpod).
///
/// Capa de aplicación entre el UI y el repository. Las pantallas escuchan
/// [authStateProvider] para saber quién está autenticado, y llaman a
/// [authControllerProvider] para ejecutar acciones (login, registro, etc).

// ============================================================
// Providers base
// ============================================================

/// Instancia única del repository. Expuesto como provider para que se pueda
/// sustituir en tests por un mock.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream reactivo del usuario actual. Núcleo del flujo de navegación:
/// el AuthGate escucha esto para decidir qué pantalla mostrar.
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

// ============================================================
// Controller
// ============================================================

/// Estado del controlador de auth. Maneja loading/error sin depender de
/// setState en cada pantalla.
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final String? infoMessage;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.infoMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? infoMessage,
    bool clearMessages = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearMessages ? null : (infoMessage ?? this.infoMessage),
    );
  }

  static const idle = AuthState();
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(AuthState.idle);

  // ---- Login ----
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      await _repo.signInWithEmail(email: email, password: password);
      state = AuthState.idle;
      return true;
    } on AuthException catch (e) {
      state = AuthState(errorMessage: e.message);
      return false;
    } catch (_) {
      state = const AuthState(errorMessage: 'Algo no salió bien.');
      return false;
    }
  }

  // ---- Registro ----
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      await _repo.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AuthState.idle;
      return true;
    } on AuthException catch (e) {
      state = AuthState(errorMessage: e.message);
      return false;
    } catch (_) {
      state = const AuthState(
        errorMessage: 'No pudimos crear tu cuenta. Intenta de nuevo.',
      );
      return false;
    }
  }

  // ---- Recuperación ----
  Future<bool> sendPasswordReset(String email) async {
    state = const AuthState(isLoading: true);
    try {
      await _repo.sendPasswordReset(email);
      state = const AuthState(
        infoMessage: 'Te enviamos un correo con instrucciones.',
      );
      return true;
    } on AuthException catch (e) {
      state = AuthState(errorMessage: e.message);
      return false;
    } catch (_) {
      state = const AuthState(errorMessage: 'No pudimos enviar el correo.');
      return false;
    }
  }

  // ---- Verificación de correo ----
  Future<bool> resendVerification() async {
    state = const AuthState(isLoading: true);
    try {
      await _repo.resendVerification();
      state = const AuthState(
        infoMessage: 'Reenviamos el correo de verificación.',
      );
      return true;
    } on AuthException catch (e) {
      state = AuthState(errorMessage: e.message);
      return false;
    } catch (_) {
      state = const AuthState(errorMessage: 'No pudimos reenviar el correo.');
      return false;
    }
  }

  /// Refresca el estado del usuario para detectar si ya verificó el correo.
  Future<bool> checkEmailVerified() async {
    return _repo.reloadAndCheckVerification();
  }

  // ---- Logout ----
  Future<void> signOut() async {
    await _repo.signOut();
    state = AuthState.idle;
  }

  /// Limpia mensajes de error/info — útil al cambiar de pantalla.
  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

/// Provider del controlador. Las pantallas lo consumen con `ref.read` para
/// disparar acciones, y con `ref.watch` para reaccionar a su estado.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
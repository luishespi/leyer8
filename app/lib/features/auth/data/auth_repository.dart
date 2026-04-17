import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthException implements Exception {
  final String code;
  final String message;
  AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException($code): $message';
}

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Registra un usuario nuevo.
  ///
  /// Una vez creada la cuenta en Auth (paso crítico), los pasos subsiguientes
  /// (displayName, doc en Firestore, correo de verificación) se ejecutan con
  /// manejo de errores individual. Si alguno falla, la sesión ya está activa —
  /// el AuthGate reencamina igual.
  Future<User> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Paso crítico: crear cuenta
    final User user;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final u = cred.user;
      if (u == null) {
        throw AuthException('user-null', 'No se pudo crear la cuenta.');
      }
      user = u;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }

    // Pasos best-effort. Fallas aquí no bloquean el flujo.
    try {
      await user.updateDisplayName(displayName.trim());
    } catch (e) {
      // ignore: avoid_print
      print('[AuthRepo] updateDisplayName fallo: $e');
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': email.trim(),
        'displayName': displayName.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': false,
        'nextdnsProfileId': null,
        'subscription': {
          'status': 'trial',
          'trialEndsAt': null,
        },
      });
    } catch (e) {
      // ignore: avoid_print
      print('[AuthRepo] firestore set fallo: $e');
    }

    try {
      await user.sendEmailVerification();
    } catch (e) {
      // ignore: avoid_print
      print('[AuthRepo] sendEmailVerification fallo: $e');
    }

    return user;
  }

  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw AuthException('user-null', 'No se pudo iniciar sesión.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> resendVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('no-session', 'No hay una sesión activa.');
    }
    if (user.emailVerified) {
      throw AuthException('already-verified', 'Tu correo ya está verificado.');
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<bool> reloadAndCheckVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  AuthException _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AuthException(e.code, 'El correo no tiene un formato válido.');
      case 'user-disabled':
        return AuthException(
          e.code,
          'Esta cuenta está desactivada. Contacta a soporte.',
        );
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthException(e.code, 'Correo o contraseña incorrectos.');
      case 'email-already-in-use':
        return AuthException(e.code, 'Ya existe una cuenta con este correo.');
      case 'weak-password':
        return AuthException(e.code, 'La contraseña es demasiado débil.');
      case 'too-many-requests':
        return AuthException(
          e.code,
          'Demasiados intentos. Intenta de nuevo en unos minutos.',
        );
      case 'network-request-failed':
        return AuthException(e.code, 'Sin conexión. Verifica tu internet.');
      case 'operation-not-allowed':
        return AuthException(
          e.code,
          'Este método de inicio de sesión no está habilitado.',
        );
      default:
        return AuthException(
          e.code,
          'Algo no salió como esperábamos. Intenta de nuevo.',
        );
    }
  }
}
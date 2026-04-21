import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../auth/application/auth_controller.dart';
import '../data/provisioning_repository.dart';

/// Providers y controlador de provisión de perfiles NextDNS (Riverpod).

// ============================================================
// Providers base
// ============================================================

/// Instancia única del repository de provisión.
final provisioningRepositoryProvider = Provider<ProvisioningRepository>((ref) {
  return ProvisioningRepository();
});

/// Stream del documento de usuario en Firestore.
///
/// Escucha cambios en `users/{uid}` — cuando el backend escribe
/// `nextdnsProfileId` tras la provisión, este stream emite y el
/// AuthGate reconstruye mostrando la siguiente pantalla.
///
/// Devuelve null si no hay usuario autenticado.
final userDocProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.data());
});

// ============================================================
// Controller
// ============================================================

class ProvisioningState {
  final bool isLoading;
  final String? errorMessage;
  final bool completed;
  final ProvisioningResult? result;

  const ProvisioningState({
    this.isLoading = false,
    this.errorMessage,
    this.completed = false,
    this.result,
  });

  static const idle = ProvisioningState();
}

class ProvisioningController extends StateNotifier<ProvisioningState> {
  final ProvisioningRepository _repo;

  ProvisioningController(this._repo) : super(ProvisioningState.idle);

  /// Ejecuta la provisión del perfil NextDNS.
  ///
  /// Llamado automáticamente por la ProvisioningScreen.
  /// Si el perfil ya existe (idempotencia del backend), simplemente
  /// marca como completado.
  Future<bool> provision() async {
    if (state.isLoading) return false;

    state = const ProvisioningState(isLoading: true);

    try {
      final result = await _repo.provisionProfile();
      state = ProvisioningState(
        completed: true,
        result: result,
      );
      return true;
    } on ProvisioningException catch (e) {
      state = ProvisioningState(
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = const ProvisioningState(
        errorMessage:
            'No pudimos activar tu protección. Verifica tu conexión e intenta de nuevo.',
      );
      return false;
    }
  }

  void reset() {
    state = ProvisioningState.idle;
  }
}

/// Provider del controlador de provisión.
final provisioningControllerProvider =
    StateNotifierProvider<ProvisioningController, ProvisioningState>((ref) {
  final repo = ref.watch(provisioningRepositoryProvider);
  return ProvisioningController(repo);
});
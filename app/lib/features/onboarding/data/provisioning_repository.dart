import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/config/app_config.dart';

/// Resultado de una provisión exitosa.
class ProvisioningResult {
  final String profileId;
  final List<String> dnsIpv4;
  final List<String> dnsIpv6;
  final String dohUrl;
  final String status;

  ProvisioningResult({
    required this.profileId,
    required this.dnsIpv4,
    required this.dnsIpv6,
    required this.dohUrl,
    required this.status,
  });

  factory ProvisioningResult.fromJson(Map<String, dynamic> json) {
    return ProvisioningResult(
      profileId: json['profileId'] as String,
      dnsIpv4: List<String>.from(json['dnsIpv4'] as List),
      dnsIpv6: List<String>.from(json['dnsIpv6'] as List),
      dohUrl: json['dohUrl'] as String,
      status: json['status'] as String,
    );
  }
}

/// Resultado de consultar el perfil existente.
class ProfileInfo {
  final String profileId;
  final String name;
  final List<String> dnsIpv4;
  final List<String> dnsIpv6;
  final String dohUrl;
  final String? provisioningStatus;
  final bool onboardingCompleted;

  ProfileInfo({
    required this.profileId,
    required this.name,
    required this.dnsIpv4,
    required this.dnsIpv6,
    required this.dohUrl,
    required this.provisioningStatus,
    required this.onboardingCompleted,
  });

  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    return ProfileInfo(
      profileId: json['profileId'] as String,
      name: json['name'] as String? ?? '',
      dnsIpv4: List<String>.from(json['dnsIpv4'] as List),
      dnsIpv6: List<String>.from(json['dnsIpv6'] as List),
      dohUrl: json['dohUrl'] as String,
      provisioningStatus: json['provisioningStatus'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }
}

class ProvisioningException implements Exception {
  final String code;
  final String message;
  final bool retryable;

  ProvisioningException(this.code, this.message, {this.retryable = false});

  @override
  String toString() => 'ProvisioningException($code): $message';
}

/// Repositorio que gestiona la provisión de perfiles NextDNS.
///
/// Toda comunicación con NextDNS pasa por el backend — el cliente
/// nunca accede a la API de NextDNS directamente. El backend verifica
/// el ID Token de Firebase antes de ejecutar cualquier acción.
class ProvisioningRepository {
  final FirebaseAuth _auth;
  final HttpClient _httpClient;

  ProvisioningRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance,
        _httpClient = HttpClient()
          ..connectionTimeout = AppConfig.httpTimeout;

  /// Obtiene el ID Token del usuario actual.
  Future<String> _getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw ProvisioningException('no-session', 'No hay sesión activa.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw ProvisioningException(
        'no-token',
        'No se pudo obtener el token de autenticación.',
      );
    }
    return token;
  }

  //// Helper para hacer requests al backend.
  Future<Map<String, dynamic>> _request(
    String method,
    String path,
  ) async {
    final token = await _getIdToken();
    final uri = Uri.parse('${AppConfig.backendUrl}$path');

    final request = await (method == 'POST'
        ? _httpClient.postUrl(uri)
        : _httpClient.getUrl(uri));

    request.headers.set('Authorization', 'Bearer $token');

    if (method == 'POST') {
      request.headers.set('Content-Type', 'application/json');
      request.write('{}');
    }

    final response = await request.close().timeout(AppConfig.httpTimeout);
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      final error = json['error'] as String? ?? 'unknown';
      final message = json['message'] as String? ?? 'Error desconocido.';
      final retryable = json['retryable'] as bool? ?? false;

      throw ProvisioningException(error, message, retryable: retryable);
    }

    return json;
  }

  /// Solicita al backend la creación del perfil NextDNS.
  ///
  /// El endpoint es idempotente: si el perfil ya existe, devuelve
  /// los datos existentes con status "already_provisioned".
  Future<ProvisioningResult> provisionProfile() async {
    final json = await _request('POST', '/api/v1/profiles/provision');
    return ProvisioningResult.fromJson(json);
  }

  /// Consulta el perfil NextDNS del usuario actual.
  ///
  /// Útil para obtener las IPs del DNS después de la provisión
  /// (por ejemplo, al entrar a la pantalla de configuración del router).
  Future<ProfileInfo> getMyProfile() async {
    final json = await _request('GET', '/api/v1/profiles/me');
    return ProfileInfo.fromJson(json);
  }
}
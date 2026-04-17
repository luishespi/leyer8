/// Validadores reusables para formularios.
///
/// Todos devuelven `null` si el input es válido, o un mensaje de error
/// (en español, tono editorial — no alarmista) si no lo es.
class FormValidators {
  FormValidators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Campo requerido.
  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido.';
    }
    return null;
  }

  /// Correo electrónico.
  static String? email(String? value) {
    final requiredError = required(value, fieldName: 'El correo');
    if (requiredError != null) return requiredError;
    if (!_emailRegExp.hasMatch(value!.trim())) {
      return 'Ingresa un correo válido.';
    }
    return null;
  }

  /// Contraseña — mínimo 8 caracteres, al menos una letra y un número.
  static String? password(String? value) {
    final requiredError = required(value, fieldName: 'La contraseña');
    if (requiredError != null) return requiredError;
    if (value!.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasNumber = RegExp(r'\d').hasMatch(value);
    if (!hasLetter || !hasNumber) {
      return 'La contraseña debe combinar letras y números.';
    }
    return null;
  }

  /// Confirmación de contraseña — debe coincidir con la original.
  static String? passwordConfirmation(String? value, String original) {
    final requiredError = required(value, fieldName: 'La confirmación');
    if (requiredError != null) return requiredError;
    if (value != original) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  /// Nombre del padre/madre — al menos 2 caracteres.
  static String? name(String? value) {
    final requiredError = required(value, fieldName: 'El nombre');
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 2) {
      return 'Ingresa un nombre válido.';
    }
    return null;
  }
}
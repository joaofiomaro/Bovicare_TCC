import 'package:formz/formz.dart';

// ---------------------------------------------------------------------------
// Email
// ---------------------------------------------------------------------------
enum EmailValidationError { empty, invalid }

class EmailInput extends FormzInput<String, EmailValidationError> {
  const EmailInput.pure() : super.pure('');
  const EmailInput.dirty([super.value = '']) : super.dirty();

  @override
  EmailValidationError? validator(String value) {
    if (value.isEmpty) return EmailValidationError.empty;
    if (!RegExp(r'^[\w\-.+]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return EmailValidationError.invalid;
    }
    return null;
  }
}

extension EmailValidationErrorX on EmailValidationError {
  String get message {
    return switch (this) {
      EmailValidationError.empty   => 'Informe seu e-mail.',
      EmailValidationError.invalid => 'E-mail inválido.',
    };
  }
}

// ---------------------------------------------------------------------------
// Password
// ---------------------------------------------------------------------------
enum PasswordValidationError { empty, tooShort }

class PasswordInput extends FormzInput<String, PasswordValidationError> {
  const PasswordInput.pure() : super.pure('');
  const PasswordInput.dirty([super.value = '']) : super.dirty();

  @override
  PasswordValidationError? validator(String value) {
    if (value.isEmpty) return PasswordValidationError.empty;
    if (value.length < 8) return PasswordValidationError.tooShort;
    return null;
  }
}

extension PasswordValidationErrorX on PasswordValidationError {
  String get message {
    return switch (this) {
      PasswordValidationError.empty    => 'Informe sua senha.',
      PasswordValidationError.tooShort => 'Senha deve ter ao menos 8 caracteres.',
    };
  }
}

// ---------------------------------------------------------------------------
// Required text (nome, fazenda, etc.)
// ---------------------------------------------------------------------------
enum RequiredValidationError { empty }

class RequiredInput extends FormzInput<String, RequiredValidationError> {
  const RequiredInput.pure() : super.pure('');
  const RequiredInput.dirty([super.value = '']) : super.dirty();

  @override
  RequiredValidationError? validator(String value) {
    if (value.trim().isEmpty) return RequiredValidationError.empty;
    return null;
  }
}

extension RequiredValidationErrorX on RequiredValidationError {
  String get message => 'Este campo é obrigatório.';
}

import 'package:bovicare/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // EmailInput
  // ---------------------------------------------------------------------------
  group('EmailInput', () {
    test('pure state is untouched (isPure)', () {
      const input = EmailInput.pure();
      expect(input.isPure, isTrue);
    });

    test('accepts valid email', () {
      const input = EmailInput.dirty('user@example.com');
      expect(input.isValid, isTrue);
    });

    test('accepts email with plus tag', () {
      const input = EmailInput.dirty('user+tag@domain.com');
      expect(input.isValid, isTrue);
    });

    test('rejects empty string', () {
      const input = EmailInput.dirty();
      expect(input.isValid, isFalse);
      expect(input.error, EmailValidationError.empty);
    });

    test('rejects missing @', () {
      const input = EmailInput.dirty('userexample.com');
      expect(input.isValid, isFalse);
      expect(input.error, EmailValidationError.invalid);
    });

    test('rejects missing domain', () {
      const input = EmailInput.dirty('user@');
      expect(input.isValid, isFalse);
    });

    test('rejects missing TLD', () {
      const input = EmailInput.dirty('user@domain');
      expect(input.isValid, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // PasswordInput
  // ---------------------------------------------------------------------------
  group('PasswordInput', () {
    test('pure state is untouched (isPure)', () {
      const input = PasswordInput.pure();
      expect(input.isPure, isTrue);
    });

    test('accepts 8-character password', () {
      const input = PasswordInput.dirty('12345678');
      expect(input.isValid, isTrue);
    });

    test('accepts long password', () {
      const input = PasswordInput.dirty('my_super_secure_password_123!');
      expect(input.isValid, isTrue);
    });

    test('rejects empty string', () {
      const input = PasswordInput.dirty();
      expect(input.isValid, isFalse);
      expect(input.error, PasswordValidationError.empty);
    });

    test('rejects password shorter than 8 characters', () {
      const input = PasswordInput.dirty('1234567');
      expect(input.isValid, isFalse);
      expect(input.error, PasswordValidationError.tooShort);
    });
  });

  // ---------------------------------------------------------------------------
  // RequiredInput
  // ---------------------------------------------------------------------------
  group('RequiredInput', () {
    test('pure state is untouched (isPure)', () {
      const input = RequiredInput.pure();
      expect(input.isPure, isTrue);
    });

    test('accepts non-empty value', () {
      const input = RequiredInput.dirty('João');
      expect(input.isValid, isTrue);
    });

    test('rejects empty string', () {
      const input = RequiredInput.dirty();
      expect(input.isValid, isFalse);
      expect(input.error, RequiredValidationError.empty);
    });

    test('rejects whitespace-only string', () {
      const input = RequiredInput.dirty('   ');
      expect(input.isValid, isFalse);
      expect(input.error, RequiredValidationError.empty);
    });
  });

  // ---------------------------------------------------------------------------
  // Error messages
  // ---------------------------------------------------------------------------
  group('Error messages', () {
    test('EmailValidationError.empty has message', () {
      expect(
        EmailValidationError.empty.message,
        isNotEmpty,
      );
    });

    test('EmailValidationError.invalid has message', () {
      expect(EmailValidationError.invalid.message, isNotEmpty);
    });

    test('PasswordValidationError.tooShort has message', () {
      expect(PasswordValidationError.tooShort.message, isNotEmpty);
    });

    test('RequiredValidationError.empty has message', () {
      expect(RequiredValidationError.empty.message, isNotEmpty);
    });
  });
}

import 'package:bovicare/core/extensions/string_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StringX.capitalize', () {
    test('capitalizes first letter and lowercases rest', () {
      expect('hello'.capitalize, 'Hello');
      expect('WORLD'.capitalize, 'World');
      expect('jOHN'.capitalize, 'John');
    });

    test('handles empty string', () {
      expect(''.capitalize, '');
    });

    test('handles single character', () {
      expect('a'.capitalize, 'A');
    });
  });

  group('StringX.titleCase', () {
    test('capitalizes each word', () {
      expect('hello world'.titleCase, 'Hello World');
      expect('bom dia fazenda'.titleCase, 'Bom Dia Fazenda');
    });

    test('handles single word', () {
      expect('flutter'.titleCase, 'Flutter');
    });
  });

  group('StringX.isValidEmail', () {
    test('accepts valid email', () {
      expect('user@example.com'.isValidEmail, isTrue);
      expect('user+tag@domain.com'.isValidEmail, isTrue);
    });

    test('rejects invalid email', () {
      expect('notanemail'.isValidEmail, isFalse);
      expect('missing@tld'.isValidEmail, isFalse);
      expect('@nodomain.com'.isValidEmail, isFalse);
    });
  });

  group('StringX.isValidPassword', () {
    test('accepts passwords with 8+ characters', () {
      expect('12345678'.isValidPassword, isTrue);
      expect('verylongpassword'.isValidPassword, isTrue);
    });

    test('rejects passwords shorter than 8 characters', () {
      expect('1234567'.isValidPassword, isFalse);
      expect(''.isValidPassword, isFalse);
    });
  });

  group('StringX.initials', () {
    test('returns first letter for single name', () {
      expect('João'.initials, 'J');
    });

    test('returns first and last initials for multiple names', () {
      expect('João Silva'.initials, 'JS');
      expect('Maria Aparecida Santos'.initials, 'MS');
    });

    test('returns uppercase initials', () {
      expect('ana maria'.initials, 'AM');
    });

    test('handles empty string', () {
      expect(''.initials, '');
    });

    test('handles whitespace-only string', () {
      expect('   '.initials, '');
    });
  });
}

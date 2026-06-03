import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bovicare/features/auth/domain/entities/user_entity.dart';
import 'package:bovicare/features/auth/domain/repositories/auth_repository.dart';
import 'package:bovicare/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:bovicare/features/auth/domain/usecases/login_use_case.dart';
import 'package:bovicare/features/auth/domain/usecases/logout_use_case.dart';
import 'package:bovicare/features/auth/domain/usecases/register_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _testUser = UserEntity(
  id:    'uid-test',
  name:  'João Produtor',
  email: 'joao@bovicare.com',
  role:  UserRole.producer,
);

void main() {
  late MockAuthRepository repo;

  setUpAll(() {
    registerFallbackValue(UserRole.producer);
  });

  setUp(() {
    repo = MockAuthRepository();
  });

  // ---------------------------------------------------------------------------
  // LoginUseCase
  // ---------------------------------------------------------------------------
  group('LoginUseCase', () {
    late LoginUseCase useCase;

    setUp(() => useCase = LoginUseCase(repo));

    test('delegates to repository and returns UserEntity', () async {
      when(() => repo.login(
            email:    any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => _testUser);

      final result = await useCase.call(
        email:    'joao@bovicare.com',
        password: 'senha123',
      );

      expect(result, _testUser);
      verify(() => repo.login(
            email:    'joao@bovicare.com',
            password: 'senha123',
          )).called(1);
    });

    test('propagates exception from repository', () {
      when(() => repo.login(
            email:    any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(Exception('auth error'));

      expect(
        () => useCase.call(email: 'e@e.com', password: 'pass'),
        throwsException,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // RegisterUseCase
  // ---------------------------------------------------------------------------
  group('RegisterUseCase', () {
    late RegisterUseCase useCase;

    setUp(() => useCase = RegisterUseCase(repo));

    test('delegates to repository with correct params', () async {
      when(() => repo.register(
            name:     any(named: 'name'),
            email:    any(named: 'email'),
            password: any(named: 'password'),
            role:     any(named: 'role'),
          )).thenAnswer((_) async => _testUser);

      final result = await useCase.call(
        name:     'João',
        email:    'joao@test.com',
        password: 'senha123',
        role:     UserRole.producer,
      );

      expect(result, _testUser);
      verify(() => repo.register(
            name:     'João',
            email:    'joao@test.com',
            password: 'senha123',
            role:     UserRole.producer,
          )).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // LogoutUseCase
  // ---------------------------------------------------------------------------
  group('LogoutUseCase', () {
    late LogoutUseCase useCase;

    setUp(() => useCase = LogoutUseCase(repo));

    test('calls repository logout', () async {
      when(() => repo.logout()).thenAnswer((_) async {});

      await useCase.call();

      verify(() => repo.logout()).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // GetCurrentUserUseCase
  // ---------------------------------------------------------------------------
  group('GetCurrentUserUseCase', () {
    late GetCurrentUserUseCase useCase;

    setUp(() => useCase = GetCurrentUserUseCase(repo));

    test('returns user when session is active', () async {
      when(() => repo.getCurrentUser())
          .thenAnswer((_) async => _testUser);

      final result = await useCase.call();

      expect(result, _testUser);
    });

    test('returns null when no session', () async {
      when(() => repo.getCurrentUser()).thenAnswer((_) async => null);

      final result = await useCase.call();

      expect(result, isNull);
    });
  });
}

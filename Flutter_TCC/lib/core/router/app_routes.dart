/// Nomes e paths de todas as rotas do app.
/// Centralizado aqui para evitar strings espalhadas no código.
abstract final class AppRoutes {
  // Auth
  static const String splash   = 'splash';
  static const String login    = 'login';
  static const String register = 'register';

  // Dashboard
  static const String dashboard = 'dashboard';

  // Herd
  static const String herd       = 'herd';
  static const String animal     = 'animal';
  static const String newAnimal       = 'new-animal';
  static const String editAnimal       = 'edit-animal';
  static const String archivedAnimals = 'archived-animals';

  // Vaccination
  static const String vaccination = 'vaccination';

  // Brete
  static const String brete = 'brete';

  // Vets
  static const String vets      = 'vets';
  static const String vetDetail = 'vet-detail';

  // Chamados (serviceCalls)
  static const String vetCalls       = 'vet-calls';
  static const String vetAgenda      = 'vet-agenda';
  static const String newServiceCall = 'new-service-call';
  static const String myServiceCalls = 'my-service-calls';

  // Reports
  static const String reports = 'reports';

  // Profile
  static const String profile = 'profile';
}

/// Paths absolutos das rotas para uso com GoRouter.
abstract final class AppPaths {
  static const String splash   = '/';
  static const String login    = '/login';
  static const String register = '/register';

  static const String dashboard = '/dashboard';
  static const String herd            = '/herd';
  static const String newAnimal       = '/herd/new';
  static const String archivedAnimals = '/herd/archived';
  static String animal(String id) => '/herd/$id';
  static String editAnimal(String id) => '/herd/$id/edit';
  static String vaccination(String animalId) => '/herd/$animalId/vaccine';

  static const String brete    = '/brete';
  static const String vets     = '/vets';
  static String vetDetail(String id) => '/vets/$id';
  static const String reports  = '/reports';
  static const String profile  = '/profile';

  static const String vetCalls       = '/calls';
  static const String vetAgenda      = '/agenda';
  static const String newServiceCall = '/new-call';
  static const String myServiceCalls = '/my-calls';
}

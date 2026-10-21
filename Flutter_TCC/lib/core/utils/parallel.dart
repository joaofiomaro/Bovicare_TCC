/// Espera paralela que propaga o PRIMEIRO erro original.
///
/// O `.wait` nativo dos records lança `ParallelWaitError`, cujo `toString()`
/// é técnico ("ParallelWaitError(...)") e esconde a `Failure` amigável que a
/// UI deveria exibir (ex.: "Você não tem permissão para acessar estes dados.").
/// `Future.wait` sem `eagerError` aguarda todos e relança o primeiro erro tal
/// como foi lançado.
library;

extension WaitFirstError2<A, B> on (Future<A>, Future<B>) {
  Future<(A, B)> get waitFirstError async {
    final r = await Future.wait<Object?>([$1, $2]);
    return (r[0] as A, r[1] as B);
  }
}

extension WaitFirstError3<A, B, C> on (Future<A>, Future<B>, Future<C>) {
  Future<(A, B, C)> get waitFirstError async {
    final r = await Future.wait<Object?>([$1, $2, $3]);
    return (r[0] as A, r[1] as B, r[2] as C);
  }
}

extension WaitFirstError4<A, B, C, D>
    on (Future<A>, Future<B>, Future<C>, Future<D>) {
  Future<(A, B, C, D)> get waitFirstError async {
    final r = await Future.wait<Object?>([$1, $2, $3, $4]);
    return (r[0] as A, r[1] as B, r[2] as C, r[3] as D);
  }
}

import '../entities/sale_record.dart';
import '../repositories/sale_repository.dart';

class GetSalesUseCase {
  const GetSalesUseCase(this._repository);
  final SaleRepository _repository;

  Future<List<SaleRecord>> call() => _repository.getAll();
}

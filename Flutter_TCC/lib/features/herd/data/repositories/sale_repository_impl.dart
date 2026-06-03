import '../../domain/entities/sale_record.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/sale_firestore_data_source.dart';
import '../models/sale_model.dart';

class SaleRepositoryImpl implements SaleRepository {
  const SaleRepositoryImpl(this._dataSource);
  final SaleFirestoreDataSource _dataSource;

  @override
  Future<List<SaleRecord>> getAll() async {
    final models = await _dataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> recordSale(SaleRecord sale) =>
      _dataSource.recordSale(SaleModel.fromEntity(sale));
}

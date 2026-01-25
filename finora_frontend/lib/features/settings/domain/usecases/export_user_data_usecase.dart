import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_data_export.dart';
import '../repositories/gdpr_repository.dart';

/// Caso de uso para exportar todos los datos del usuario
///
/// Implementa el derecho de portabilidad según el Artículo 20 del GDPR.
/// Permite al usuario obtener una copia de todos sus datos personales
/// en un formato estructurado, de uso común y lectura mecánica.
class ExportUserDataUseCase implements UseCase<UserDataExport, NoParams> {
  final GDPRRepository repository;

  ExportUserDataUseCase(this.repository);

  @override
  Future<Either<Failure, UserDataExport>> call(NoParams params) async {
    return await repository.exportUserData();
  }
}

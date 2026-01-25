import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Clase abstracta base para todos los casos de uso
///
/// Define el contrato que deben seguir todos los casos de uso
/// de la aplicación, siguiendo los principios de Clean Architecture.
///
/// [Result] es el tipo de retorno del caso de uso
/// [Params] son los parámetros requeridos para ejecutar el caso de uso
abstract class UseCase<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

/// Clase para casos de uso que no requieren parámetros
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}

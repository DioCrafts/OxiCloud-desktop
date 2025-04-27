import 'package:dartz/dartz.dart';
import 'package:oxicloud_desktop_client/core/error/failures.dart';
import 'package:oxicloud_desktop_client/core/usecases/usecase.dart';
import 'package:oxicloud_desktop_client/features/settings/domain/models/settings.dart';
import 'package:oxicloud_desktop_client/features/settings/domain/ports/settings_repository.dart';

class UpdateSettingsUseCase implements UseCase<void, Settings> {
  final SettingsRepository repository;

  UpdateSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Settings params) async {
    return await repository.updateSettings(params);
  }
} 
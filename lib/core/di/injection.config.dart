// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/auth/application/usecases/auth_usecase.dart' as _i325;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/ports/auth_repository.dart' as _i335;
import '../../features/auth/domain/usecases/auth_usecase.dart' as _i436;
import '../../features/auth/infrastructure/repositories/auth_repository_impl.dart'
    as _i748;
import '../../features/auth/presentation/providers/auth_provider.dart'
    as _i1054;
import 'shared_preferences_module.dart' as _i110;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final sharedPreferencesModule = _$SharedPreferencesModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => sharedPreferencesModule.prefs,
      preResolve: true,
    );
    gh.factory<_i335.AuthRepository>(() => _i153.AuthRepositoryImpl(
          gh<InvalidType>(),
          gh<_i460.SharedPreferences>(),
        ));
    gh.factory<_i748.AuthRepositoryImpl>(() => _i748.AuthRepositoryImpl(
          gh<InvalidType>(),
          gh<_i460.SharedPreferences>(),
        ));
    gh.factory<_i436.AuthUseCase>(
        () => _i436.AuthUseCase(gh<_i335.AuthRepository>()));
    gh.factory<_i325.AuthUseCase>(
        () => _i325.AuthUseCase(gh<_i335.AuthRepository>()));
    gh.factory<_i1054.AuthProvider>(
        () => _i1054.AuthProvider(gh<_i325.AuthUseCase>()));
    return this;
  }
}

class _$SharedPreferencesModule extends _i110.SharedPreferencesModule {}

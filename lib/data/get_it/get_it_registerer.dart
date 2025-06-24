import 'package:get_it/get_it.dart';

class GetItRegisterer {
  static void registerValue<T extends Object>({required T value, String? name}) {
    final getIt = GetIt.instance;

    if (getIt.isRegistered<T>(instanceName: name)) {
      getIt.unregister<T>(instanceName: name);
    }

    getIt.registerSingleton<T>(value, instanceName: name);
  }
}

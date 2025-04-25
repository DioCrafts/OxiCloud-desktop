// Stub file to avoid loading flutter_secure_storage on Linux
// This prevents CMake from trying to find libsecret

// Define a stub class that won't be used but allows compilation to succeed
class FlutterSecureStorage {
  const FlutterSecureStorage({
    dynamic aOptions,
    dynamic iOptions,
    dynamic mOptions,
    dynamic lOptions,
    dynamic wOptions,
  });
  
  Future<String?> read({required String key}) async => null;
  Future<void> write({required String key, required String? value}) async {}
  Future<void> delete({required String key}) async {}
  Future<void> deleteAll() async {}
}

class AndroidOptions {
  const AndroidOptions({bool? encryptedSharedPreferences});
}

class IOSOptions {
  const IOSOptions({dynamic accessibility});
}

class MacOsOptions {
  const MacOsOptions({dynamic accessibility});
}

class WindowsOptions {
  const WindowsOptions();
}

class LinuxOptions {
  const LinuxOptions();
}

class KeychainAccessibility {
  static const dynamic first_unlock = null;
}
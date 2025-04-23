import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';

/// Device capability classification
enum DeviceClass {
  /// Low-end device with limited resources
  low,
  
  /// Mid-range device with average resources
  medium,
  
  /// High-end device with abundant resources
  high,
}

/// Information about the device's capabilities
class DeviceCapability {
  /// Total RAM in bytes
  final int totalRam;
  
  /// Number of CPU cores
  final int cpuCores;
  
  /// Device class based on its capabilities
  final DeviceClass deviceClass;
  
  /// Device model name
  final String modelName;
  
  /// Operating system name
  final String osName;
  
  /// Operating system version
  final String osVersion;
  
  const DeviceCapability({
    required this.totalRam,
    required this.cpuCores,
    required this.deviceClass,
    required this.modelName,
    required this.osName,
    required this.osVersion,
  });
  
  @override
  String toString() => 'DeviceCapability('
      'totalRam: ${(totalRam / (1024 * 1024)).toStringAsFixed(2)} MB, '
      'cpuCores: $cpuCores, '
      'deviceClass: $deviceClass, '
      'modelName: $modelName, '
      'osName: $osName, '
      'osVersion: $osVersion)';
}

/// Service for gathering device information
class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Logger _logger = LoggingManager.getLogger('DeviceInfoService');
  
  DeviceCapability? _deviceCapability;
  
  /// Get device capability information
  Future<DeviceCapability> getDeviceCapability() async {
    if (_deviceCapability != null) {
      return _deviceCapability!;
    }
    
    _deviceCapability = await _getDeviceCapabilityInternal();
    return _deviceCapability!;
  }
  
  Future<DeviceCapability> _getDeviceCapabilityInternal() async {
    try {
      if (kIsWeb) {
        return await _getWebDeviceCapability();
      } else if (Platform.isAndroid) {
        return await _getAndroidDeviceCapability();
      } else if (Platform.isIOS) {
        return await _getIosDeviceCapability();
      } else if (Platform.isLinux) {
        return await _getLinuxDeviceCapability();
      } else if (Platform.isMacOS) {
        return await _getMacOsDeviceCapability();
      } else if (Platform.isWindows) {
        return await _getWindowsDeviceCapability();
      } else {
        return _getDefaultDeviceCapability();
      }
    } catch (e) {
      _logger.warning('Failed to get device info: $e');
      return _getDefaultDeviceCapability();
    }
  }
  
  Future<DeviceCapability> _getAndroidDeviceCapability() async {
    final androidInfo = await _deviceInfo.androidInfo;
    
    // Calculate RAM in bytes (some devices might not report correctly)
    int totalRam = 2 * 1024 * 1024 * 1024; // 2GB default
    
    // Get CPU cores (physical cores if available)
    int cpuCores = androidInfo.supportedAbis?.length ?? 2;
    
    // Determine device class based on RAM and Android version
    DeviceClass deviceClass;
    if (totalRam >= 6 * 1024 * 1024 * 1024 && androidInfo.version.sdkInt >= 28) {
      deviceClass = DeviceClass.high;
    } else if (totalRam >= 3 * 1024 * 1024 * 1024 && androidInfo.version.sdkInt >= 24) {
      deviceClass = DeviceClass.medium;
    } else {
      deviceClass = DeviceClass.low;
    }
    
    return DeviceCapability(
      totalRam: totalRam,
      cpuCores: cpuCores,
      deviceClass: deviceClass,
      modelName: androidInfo.model,
      osName: 'Android',
      osVersion: androidInfo.version.release,
    );
  }
  
  Future<DeviceCapability> _getIosDeviceCapability() async {
    final iosInfo = await _deviceInfo.iosInfo;
    
    // iOS doesn't provide RAM info, estimate based on model
    int totalRam = 4 * 1024 * 1024 * 1024; // 4GB default
    int cpuCores = 2; // Default
    
    // Determine device class based on model and iOS version
    DeviceClass deviceClass;
    final model = iosInfo.model ?? '';
    final majorVersion = int.tryParse(iosInfo.systemVersion.split('.').first) ?? 0;
    
    bool isNewerIPhone = false;
    if (model.contains('iPhone')) {
      int? phoneNumber = int.tryParse(model.replaceAll(RegExp(r'[^0-9]'), ''));
      isNewerIPhone = (phoneNumber != null && phoneNumber >= 11);
    }
    
    if (isNewerIPhone) {
      deviceClass = DeviceClass.high;
      totalRam = 6 * 1024 * 1024 * 1024; // 6GB estimate for newer iPhones
      cpuCores = 6;
    } else if (majorVersion >= 13) {
      deviceClass = DeviceClass.medium;
      totalRam = 4 * 1024 * 1024 * 1024; // 4GB estimate
      cpuCores = 4;
    } else {
      deviceClass = DeviceClass.low;
      totalRam = 2 * 1024 * 1024 * 1024; // 2GB estimate for older devices
      cpuCores = 2;
    }
    
    return DeviceCapability(
      totalRam: totalRam,
      cpuCores: cpuCores,
      deviceClass: deviceClass,
      modelName: iosInfo.model ?? 'iOS Device',
      osName: 'iOS',
      osVersion: iosInfo.systemVersion,
    );
  }
  
  Future<DeviceCapability> _getLinuxDeviceCapability() async {
    final linuxInfo = await _deviceInfo.linuxInfo;
    
    // Linux doesn't provide standardized info, use reasonable defaults
    int totalRam = 8 * 1024 * 1024 * 1024; // 8GB default for desktop
    int cpuCores = 4; // Default
    
    return DeviceCapability(
      totalRam: totalRam,
      cpuCores: cpuCores,
      deviceClass: DeviceClass.high, // Assume desktop is high-end
      modelName: linuxInfo.prettyName,
      osName: 'Linux',
      osVersion: linuxInfo.version ?? '',
    );
  }
  
  Future<DeviceCapability> _getMacOsDeviceCapability() async {
    final macOsInfo = await _deviceInfo.macOsInfo;
    
    // MacOS devices are generally high-end
    int totalRam = 16 * 1024 * 1024 * 1024; // 16GB default
    int cpuCores = int.tryParse(macOsInfo.activeCPUs.toString()) ?? 4;
    
    return DeviceCapability(
      totalRam: totalRam,
      cpuCores: cpuCores,
      deviceClass: DeviceClass.high,
      modelName: macOsInfo.model,
      osName: 'macOS',
      osVersion: macOsInfo.osRelease,
    );
  }
  
  Future<DeviceCapability> _getWindowsDeviceCapability() async {
    final windowsInfo = await _deviceInfo.windowsInfo;
    
    // Windows devices are generally medium to high-end
    int totalRam = 8 * 1024 * 1024 * 1024; // 8GB default
    int cpuCores = 4; // Default
    
    return DeviceCapability(
      totalRam: totalRam,
      cpuCores: cpuCores,
      deviceClass: DeviceClass.medium,
      modelName: windowsInfo.computerName ?? "Windows",
      osName: 'Windows',
      osVersion: windowsInfo.buildNumber.toString(),
    );
  }
  
  Future<DeviceCapability> _getWebDeviceCapability() async {
    final webInfo = await _deviceInfo.webBrowserInfo;
    
    // Web has limited device info, use conservative defaults
    int totalRam = 4 * 1024 * 1024 * 1024; // 4GB default
    int cpuCores = 2; // Default
    
    return DeviceCapability(
      totalRam: totalRam,
      cpuCores: cpuCores,
      deviceClass: DeviceClass.medium,
      modelName: webInfo.browserName.toString(),
      osName: webInfo.platform ?? 'Web',
      osVersion: webInfo.appVersion ?? '',
    );
  }
  
  DeviceCapability _getDefaultDeviceCapability() {
    // Conservative defaults
    return const DeviceCapability(
      totalRam: 2 * 1024 * 1024 * 1024, // 2GB
      cpuCores: 2,
      deviceClass: DeviceClass.low,
      modelName: 'Unknown Device',
      osName: 'Unknown OS',
      osVersion: 'Unknown Version',
    );
  }
  
  /// Get device class (low, medium, high)
  Future<DeviceClass> getDeviceClass() async {
    final capability = await getDeviceCapability();
    return capability.deviceClass;
  }
  
  /// Get total RAM in bytes
  Future<int> getTotalRam() async {
    final capability = await getDeviceCapability();
    return capability.totalRam;
  }
  
  /// Get number of CPU cores
  Future<int> getCpuCores() async {
    final capability = await getDeviceCapability();
    return capability.cpuCores;
  }
  
  /// Get a descriptive string about the device
  Future<String> getDeviceDescription() async {
    final capability = await getDeviceCapability();
    return '${capability.modelName} (${capability.osName} ${capability.osVersion})';
  }
}
class AppConfig {
  final int menuVersion;
  final bool isMaintenance;
  final int androidVersion;
  final int iosVersion;

  AppConfig({
    required this.menuVersion,
    required this.isMaintenance,
    required this.androidVersion,
    required this.iosVersion,
  });

  // Factory method to parse JSON into AppConfig
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      menuVersion: json['menuVersion'],
      isMaintenance: json['isMaintenance'],
      androidVersion: json['AndroidVersion'],
      iosVersion: json['IOSVersion'],
    );
  }
}

class FvmConfig {
  final String flutterSdkVersion;
  FvmConfig(this.flutterSdkVersion);

  FvmConfig.fromJson(Map<String, dynamic> json)
      : flutterSdkVersion = json['flutterSdkVersion'] as String;

  Map<String, dynamic> toJson() => {'flutterSdkVersion': flutterSdkVersion};
}

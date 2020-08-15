class ProjectConfig {
  final String flutterSdkVersion;
  ProjectConfig(this.flutterSdkVersion);

  ProjectConfig.fromJson(Map<String, dynamic> json)
      : flutterSdkVersion = json['flutterSdkVersion'] as String;

  Map<String, dynamic> toJson() => {'flutterSdkVersion': flutterSdkVersion};
}

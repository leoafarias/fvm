import 'dart:convert';
import 'package:fvm/src/version.dart';
import 'package:http/http.dart' as http;
import 'package:io/ansi.dart';
import 'package:version/version.dart';

PubPackage pubPackageFromMap(String str) =>
    PubPackage.fromMap(json.decode(str) as Map<String, dynamic>);

String pubPackageToMap(PubPackage data) => json.encode(data.toMap());

/// Pub.dev FVM info
const kPubDevUrl = 'https://pub.dev/packages/fvm.json';

class PubPackage {
  PubPackage({
    this.name,
    this.uploaders,
    this.versions,
  });

  final String name;
  final List<String> uploaders;
  final List<String> versions;

  factory PubPackage.fromMap(Map<String, dynamic> json) {
    // final uploaders = json['uploaders'] as List<String>;
    return PubPackage(
      name: json['name'] as String,
      uploaders: List<String>.from(json['uploaders'] as List<dynamic>),
      versions: List<String>.from(json['versions'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'uploaders': List<dynamic>.from(uploaders.map((x) => x)),
        'versions': List<dynamic>.from(versions.map((x) => x)),
      };
}

Future<PubPackage> _fetchPubPackageInfo() async {
  final response = await http.get(kPubDevUrl);
  return pubPackageFromMap(response.body);
}

Future<bool> checkIfLatestVersion({String currentVersion}) async {
  try {
    // option to pass currentVersion for testing
    currentVersion ??= packageVersion;
    final pubPackage = await _fetchPubPackageInfo();

    final latestVersion = pubPackage.versions.last;

    if (Version.parse(currentVersion) < Version.parse(latestVersion)) {
      final updateCmd = cyan.wrap('pub global activate fvm');

      print(divider);
      print(
          'FVM Update Available $packageVersion → ${green.wrap(latestVersion)} ');
      print(
          '${yellow.wrap('Changelog:')} https://github.com/leoafarias/fvm/releases/tag/$latestVersion');
      print('Run $updateCmd to update');
      print(divider);
      return false;
    }
    return true;
  } on Exception {
    // Don't do anything fail silently
    return true;
  }
}

String get divider {
  return yellow
      .wrap('\n___________________________________________________\n\n');
}

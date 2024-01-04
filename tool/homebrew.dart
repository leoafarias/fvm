import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fvm/src/utils/http.dart';
import 'package:grinder/grinder.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'grind.dart';

GrinderTask homebrewTask() => GrinderTask(
      'homebrew-formula',
      taskFunction: _homebrewFormula,
    );

Future<void> _homebrewFormula() async {
  final githubToken = Platform.environment['GITHUB_TOKEN'] ?? '';
  final args = context.invocation.arguments;
  final versionArg = args.getOption('version');

  if (versionArg == null) {
    throw Exception('Version is required');
  }

  final url = Uri.parse(
    'https://api.github.com/repos/$owner/$repo/releases/tags/$versionArg',
  );
  final headers = {
    if (githubToken.isNotEmpty) 'Authorization': 'token $githubToken',
    'Accept': 'application/vnd.github.v3+json',
  };

  final response = await fetch(url.toString(), headers: headers);

  final Map<String, dynamic> release = json.decode(response);
  final List<dynamic> assets = release['assets'];
  final Map<String, dynamic> assetData = {};

  for (final asset in assets) {
    final assetUrl = Uri.parse(asset['browser_download_url']);
    final filename = path.basename(assetUrl.path);

    if (!filename.contains('macos-x64') && !filename.contains('macos-arm64')) {
      continue;
    }

    final sha256Hash = await _downloadFile(assetUrl, filename, headers);

    if (sha256Hash.isNotEmpty) {
      assetData[filename] = {
        'url': asset['browser_download_url'],
        'sha256': sha256Hash,
      };
    }
  }

  final template = File('tool/fvm.template.rb').readAsStringSync();

  final macosX64 = assetData['fvm-$versionArg-macos-x64.tar.gz'];
  final macosArm64 = assetData['fvm-$versionArg-macos-arm64.tar.gz'];

  final formula = template
      .replaceAll('{{VERSION}}', versionArg)
      .replaceAll('{{MACOS_X64_URL}}', macosX64['url'])
      .replaceAll('{{MACOS_X64_SHA256}}', macosX64['sha256'])
      .replaceAll('{{MACOS_ARM64_URL}}', macosArm64['url'])
      .replaceAll('{{MACOS_ARM64_SHA256}}', macosArm64['sha256']);

  final file = File('fvm.rb');
  file.writeAsStringSync(formula);
}

Future<String> _downloadFile(
  Uri url,
  String filename,
  Map<String, String> headers,
) async {
  final response = await http.get(url, headers: headers);
  if (response.statusCode == 200) {
    final bytes = response.bodyBytes;
    await File(filename).writeAsBytes(bytes);
    print('Downloaded: $filename');

    // Calculate SHA-256 hash
    final sha256Hash = sha256.convert(bytes).toString();
    print('SHA-256 Hash: $sha256Hash');
    return sha256Hash;
  }
  print('Failed to download $filename: ${response.statusCode}');
  return '';
}

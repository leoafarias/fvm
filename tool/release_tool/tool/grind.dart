import 'dart:convert';
import 'dart:io';

import 'package:cli_pkg/cli_pkg.dart' as pkg;
import 'package:grinder/grinder.dart';
import 'package:path/path.dart' as p;

const _packageName = 'fvm';
const _owner = 'leoafarias';
const _repo = 'fvm';

final Directory _releaseToolRoot = Directory.current;
final Directory _repoRoot =
    Directory(p.normalize(p.join(_releaseToolRoot.path, '..', '..')));

void main(List<String> args) {
  final enableVersionedFormula = args.contains('--versioned-formula');

  pkg.name.value = _packageName;
  pkg.humanName.value = _packageName;
  pkg.useExe.value = (_) => true;
  pkg.githubUser.value = _owner;
  pkg.githubRepo.value = '$_owner/$_packageName';
  pkg.homebrewRepo.value = '$_owner/homebrew-$_packageName';
  pkg.githubBearerToken.value = Platform.environment['GITHUB_TOKEN'];
  pkg.standaloneName.value = _packageName;

  if (enableVersionedFormula) {
    pkg.homebrewCreateVersionedFormula.value = true;
  }

  // Run all Grinder tasks from the repository root so cli_pkg works as before.
  Directory.current = _repoRoot;

  pkg.addAllTasks();
  grind(args);
}

@Task('Get all releases')
Future<void> getReleases() async {
  final response = await _githubRequest(
    Uri.parse(
      'https://api.github.com/repos/$_owner/$_repo/releases?per_page=100',
    ),
  );

  final releases = jsonDecode(response) as List<dynamic>;
  final buffer = StringBuffer();

  for (final release in releases) {
    final tagName = release['tag_name'];
    final date = release['published_at'];
    log('Release: $tagName, Date: $date');
    buffer.writeln('Release: $tagName, Date: $date');
  }

  final file = File(p.join(_repoRoot.path, 'releases.txt'));
  file.writeAsStringSync(buffer.toString());
}

@Task('Move install scripts to public directory')
void moveScripts() {
  final scriptsDir = Directory(p.join(_repoRoot.path, 'scripts'));
  if (!scriptsDir.existsSync()) {
    fail('Scripts directory does not exist at ${scriptsDir.path}');
  }

  final publicDir = Directory(p.join(_repoRoot.path, 'docs/public'));
  if (!publicDir.existsSync()) {
    fail('Public directory does not exist at ${publicDir.path}');
  }

  final installScript = File(p.join(scriptsDir.path, 'install.sh'));
  if (!installScript.existsSync()) {
    fail('install.sh does not exist in ${scriptsDir.path}');
  }

  installScript.copySync(p.join(publicDir.path, 'install.sh'));
  log('Moved install.sh to ${publicDir.path}');
}

Future<String> _githubRequest(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json');
    final token = Platform.environment['GITHUB_TOKEN'];
    if (token != null && token.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'token $token');
    }

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 400) {
      fail(
        'GitHub request to $uri failed with status '
        '${response.statusCode}: $body',
      );
    }

    return body;
  } finally {
    client.close();
  }
}

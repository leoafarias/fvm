import 'dart:convert';
import 'dart:io';

import 'package:cli_pkg/cli_pkg.dart' as pkg;
import 'package:grinder/grinder.dart';
import 'package:path/path.dart' as p;
import 'package:meta/meta.dart';

const _packageName = 'fvm';
const _owner = 'leoafarias';
const _repo = 'fvm';

final Directory _releaseToolRoot = Directory.current;
final Directory _repoRoot =
    Directory(p.normalize(p.join(_releaseToolRoot.path, '..', '..')));

@visibleForTesting
Directory? repoRootOverride;

@visibleForTesting
Future<String> Function(Uri uri)? httpRequestOverride;

Directory get _effectiveRepoRoot => repoRootOverride ?? _repoRoot;

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
  // cli_pkg expects to find pubspec.yaml, bin/, and lib/ in the current working
  // directory. Because this grind.dart lives under tool/release_tool/, we need
  // to change to the repo root before invoking cli_pkg tasks.
  Directory.current = _effectiveRepoRoot;

  pkg.addAllTasks();
  grind(args);
}

@Task('Get all releases')
Future<void> getReleases() async {
  try {
    final response = await _githubRequest(
      Uri.parse(
        'https://api.github.com/repos/$_owner/$_repo/releases?per_page=100',
      ),
    );

    final dynamic decoded = jsonDecode(response);

    if (decoded is! List) {
      _fail(
        'Unexpected GitHub release response format. '
        'Expected a JSON list but received ${decoded.runtimeType}.',
      );
    }

    final buffer = StringBuffer();

    for (final release in decoded) {
      if (release is! Map<String, dynamic>) {
        log(
          'Warning: skipping unexpected release payload: '
          '$release',
        );
        continue;
      }

      final tagName = release['tag_name'] as String?;
      final date = release['published_at'] as String?;

      if (tagName == null || date == null) {
        log(
          'Warning: skipping release with missing tag/date: '
          '$release',
        );
        continue;
      }

      log('Release: $tagName, Date: $date');
      buffer.writeln('Release: $tagName, Date: $date');
    }

    final file = File(p.join(_effectiveRepoRoot.path, 'releases.txt'));
    file.writeAsStringSync(buffer.toString());
  } on FormatException catch (error) {
    _fail(
      'Failed to parse GitHub release response as JSON. '
      'Error: $error',
    );
  } on GrinderException {
    rethrow;
  } catch (error, stackTrace) {
    _fail(
      'Failed to retrieve GitHub releases: $error\n$stackTrace',
    );
  }
}

@Task('Move install scripts to public directory')
void moveScripts() {
  final scriptsDir = Directory(p.join(_effectiveRepoRoot.path, 'scripts'));
  if (!scriptsDir.existsSync()) {
    _fail('Scripts directory does not exist at ${scriptsDir.path}');
  }

  final publicDir =
      Directory(p.join(_effectiveRepoRoot.path, 'docs/public'));
  if (!publicDir.existsSync()) {
    _fail('Public directory does not exist at ${publicDir.path}');
  }

  for (final scriptName in ['install.sh', 'uninstall.sh']) {
    final source = File(p.join(scriptsDir.path, scriptName));
    if (!source.existsSync()) {
      _fail('$scriptName does not exist in ${scriptsDir.path}');
    }

    source.copySync(p.join(publicDir.path, scriptName));
    log('Moved $scriptName to ${publicDir.path}');
  }
}

Future<String> _githubRequest(Uri uri) async {
  final override = httpRequestOverride;
  if (override != null) {
    return override(uri);
  }

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
      _fail(
        'GitHub request to $uri failed with status '
        '${response.statusCode}: $body',
      );
    }

    return body;
  } finally {
    client.close();
  }
}

@visibleForTesting
Future<String> githubRequestForTesting(Uri uri) => _githubRequest(uri);

bool get _hasGrinderContext {
  try {
    // Accessing grinder will throw when running outside of a Grinder task.
    context.grinder;
    return true;
  } catch (_) {
    return false;
  }
}

Never _fail(String message) {
  if (_hasGrinderContext) {
    return fail(message);
  }

  throw GrinderException(message);
}

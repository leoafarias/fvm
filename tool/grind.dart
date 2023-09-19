import 'dart:convert';
import 'dart:io';

import 'package:cli_pkg/cli_pkg.dart' as pkg;
import 'package:grinder/grinder.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec2/pubspec2.dart';

void main(List<String> args) {
  pkg.name.value = 'fvm';
  pkg.humanName.value = 'fvm';
  pkg.githubUser.value = 'fluttertools';
  pkg.homebrewRepo.value = 'leoafarias/homebrew-fvm';

  pkg.addAllTasks();
  grind(args);
}

@Task('Builds the version file')
// Allows to pass a version argument
// Example: grind build-version --version 3.0.0
buildVersion() async {
  TaskArgs args = context.invocation.arguments;

  String? versionArg = args.getOption('version');

  // Get the pubspec file
  final pubspec = await PubSpec.load(Directory.current);

  // Get the version
  Version? currentVersion = pubspec.version;

  Version? version = pubspec.version;

  if (versionArg != null) {
    version = Version.parse(versionArg);
  }

  log(currentVersion.toString());

  if (version != pubspec.version) {
    // change the dependencies to a single path dependency on project 'foo'
    var newPubSpec = pubspec.copy(
      version: version,
    );

    // save it
    await newPubSpec.save(Directory.current);
  }

  final versionFile = File(
    path.join(Directory.current.path, 'lib', 'src', 'version.g.dart'),
  );

  if (!versionFile.existsSync()) {
    versionFile.createSync(recursive: true);
  }

// Write the following:
// const packageVersion = '2.4.1';
  versionFile.writeAsStringSync(
    "const packageVersion = '$version';",
  );

  log('Version $version written to version.g.dart');
}

@Task('Get all releases')
Future<void> getReleases() async {
  String owner = 'leoafarias';
  String repo = 'fvm';

  final response = await http.get(
    Uri.parse(
        'https://api.github.com/repos/$owner/$repo/releases?per_page=100'),
    headers: {'Accept': 'application/vnd.github.v3+json'},
  );

  final stringBuffer = StringBuffer();

  if (response.statusCode == 200) {
    List<dynamic> releases = jsonDecode(response.body);
    for (var release in releases) {
      String tagName = release['tag_name'];
      String date = release['published_at'];
      print('Release: $tagName, Date: $date');
      stringBuffer.writeln('Release: $tagName, Date: $date');
    }
  } else {
    print('Failed to load releases. HTTP Status: ${response.statusCode}');
  }

  final file = File(
    path.join(Directory.current.path, 'releases.txt'),
  );

  file.writeAsStringSync(stringBuffer.toString());
}

@Task('Test')
Future<void> test() async {
  await runAsync('dart', arguments: ['test', '--coverage=coverage']);
}

@Task('Gather coverage and generate report')
Future<void> coverage() async {
  final coverageDir = Directory(
    path.join(Directory.current.path, 'coverage'),
  );
  // Clean up coverage directory
  await coverageDir.delete(recursive: true);

  await runAsync(
    'dart',
    arguments: [
      'pub',
      'global',
      'run',
      'coverage:format_coverage',
      '--lcov',
      '--packages=.dart_tool/package_config.json',
      '--report-on=lib/',
      '--in=coverage',
      '--out=coverage/lcov.info'
    ],
  );

  await runAsync(
    'genhtml',
    arguments: ['coverage/lcov.info', '-o', 'coverage/html'],
  );
}

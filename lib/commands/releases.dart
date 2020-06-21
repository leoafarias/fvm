// import 'dart:io';

// import 'package:io/ansi.dart';
import 'package:args/command_runner.dart';
import 'package:console/console.dart';
// import 'package:fvm/utils/print.dart';

import 'package:fvm/utils/releases_helper.dart';
// import 'package:fvm/utils/print.dart';
// import 'package:fvm/constants.dart';

/// List installed SDK Versions
class ReleasesCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'releases';

  @override
  final description = 'Lists Flutter SDK releases.';

  /// Constructor
  ReleasesCommand();

  @override
  void run() async {
    final flutterReleases = await fetchReleases();

    final releases = flutterReleases.releases;
    final outputReleases = releases.map((release) {
      return '${release.version}';
    }).toList();
    var chooser = Chooser<String>(
      outputReleases,
      message: 'Select a version: ',
    );

    var version = chooser.chooseSync();
    print('You chose $version.');
  }
}

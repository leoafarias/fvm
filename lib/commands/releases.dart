import 'package:args/command_runner.dart';
import 'package:console/console.dart';

import 'package:fvm/utils/releases_helper.dart';
import 'package:fvm/utils/version_installer.dart';

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
    final channels = flutterReleases.currentRelease.toMap();

    final list = <String>[];

    channels.forEach((key, value) {
      list.add('$key: $value');
    });

    var chooser = Chooser<String>(
      list,
      message: 'Select a release: ',
    );

    var version = chooser.chooseSync();

    channels.forEach((key, value) {
      if (version == '$key: $value') {
        installFlutterVersion(value as String);
      }
    });
    print('You chose $version');
  }
}

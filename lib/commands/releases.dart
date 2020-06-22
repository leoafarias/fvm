import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:date_format/date_format.dart';
import 'package:io/ansi.dart';

import 'package:fvm/utils/releases_helper.dart';

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
    final releases = await getReleases();
    final channels = releases.channels.toHashMap();
    final versions = releases.versions.reversed;

    versions.forEach((r) {
      final channel = channels[r.hash];
      final channelOutput = green.wrap('$channel');
      final version = yellow.wrap(r.version.padRight(17));
      final pipe = Icon.PIPE_VERTICAL;
      final friendlyDate =
          formatDate(r.releaseDate, [M, ' ', d, ' ', yy]).padRight(10);
      if (channel != null) {
        print('----------$channelOutput----------');
        print('$friendlyDate $pipe $version');
      } else {
        print('$friendlyDate $pipe $version');
      }
    });
  }
}

import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:date_format/date_format.dart';
import 'package:io/ansi.dart';

import 'package:fvm/src/releases_api/releases_client.dart';
import 'package:io/io.dart';

/// List installed SDK Versions
class ReleasesCommand extends Command<int> {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'releases';

  @override
  final description = 'Lists Flutter SDK releases.';

  /// Constructor
  ReleasesCommand();

  @override
  Future<int> run() async {
    final releases = await fetchFlutterReleases();

    final versions = releases.releases.reversed;

    versions.forEach((r) {
      final version = yellow.wrap(r.version.padRight(17));
      final pipe = Icon.PIPE_VERTICAL;
      final friendlyDate =
          formatDate(r.releaseDate, [M, ' ', d, ' ', yy]).padRight(10);

      if (r.activeChannel) {
        final channel = r.channel.toString().split('.').last;
        print('--------------------------------------');
        print('$friendlyDate $pipe $version $channel');
        print('--------------------------------------');
      } else {
        print('$friendlyDate $pipe $version');
      }
    });
    return ExitCode.success.code;
  }
}

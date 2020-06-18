import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';
import 'package:io/ansi.dart';

Future<void> installFlutterVersion(String flutterVersion) async {
  if (flutterVersion == null) {
    throw ExceptionMissingChannelVersion();
  }
  final version = flutterVersion.toLowerCase();
  final isChannel = isFlutterChannel(version);

  final progress = logger.progress(green.wrap('Downloading $version'));
  if (isChannel) {
    await flutterChannelClone(version);
  } else {
    await flutterVersionClone(version);
  }
  finishProgress(progress);
}

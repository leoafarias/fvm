import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';

Future<void> installFlutterVersion(String flutterVersion) async {
  if (flutterVersion == null) {
    throw ExceptionMissingChannelVersion();
  }
  final version = flutterVersion.toLowerCase();
  final isChannel = isFlutterChannel(version);

  if (isChannel) {
    await flutterChannelClone(version);
  } else {
    await flutterVersionClone(version);
  }
  await linkProjectFlutterDir(version);
}

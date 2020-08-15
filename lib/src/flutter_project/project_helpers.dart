import 'package:fvm/constants.dart';

bool isFlutterProject() {
  return kLocalProjectPubspec.existsSync();
}

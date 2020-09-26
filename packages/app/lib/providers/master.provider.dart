import 'package:fvm_app/providers/flutter_releases.provider.dart';
import 'package:hooks_riverpod/all.dart';

// ignore: top_level_function_literal_block
final masterProvider = Provider((ref) {
  return ref.watch(releasesStateProvider).master;
});

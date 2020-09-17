// ignore: top_level_function_literal_block
import 'package:fvm_app/providers/channels.provider.dart';
import 'package:fvm_app/providers/flutter_releases.provider.dart';
import 'package:fvm_app/providers/releases.provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// ignore: top_level_function_literal_block
final installedVersionsProvider = Provider((ref) {
  final releases = ref.watch(installedReleasesProvider);
  final channels = ref.watch(installedChannelsProvider);
  final master = ref.watch(releasesStateProvider).master;
  final versions = [...channels.all, ...releases.all];
  // If channel is installed
  if (master != null && master.isInstalled) {
    versions.insert(0, master);
  }
  return versions;
});

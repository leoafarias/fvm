import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:state_notifier/state_notifier.dart';
import 'package:watcher/watcher.dart';
import 'package:fvm_app/utils/debounce.dart';
import 'package:fvm_app/utils/dir_stat.dart';

import 'package:fvm/constants.dart' as fvm_constants;
import 'package:fvm/fvm.dart';

@deprecated
enum InstalledStatus {
  notInstalled,
  asChannel,
  asVersion,
}

final fvmCacheSizeProvider = StateProvider<String>((_) => null);

/// Releases  InfoProvider
final fvmCacheProvider = StateNotifierProvider<FvmCacheProvider>((ref) {
  return FvmCacheProvider(ref: ref, initialState: []);
});

class FvmCacheProvider extends StateNotifier<List<LocalVersion>> {
  ProviderReference ref;
  List<LocalVersion> channels;
  List<LocalVersion> versions;

  StreamSubscription<WatchEvent> directoryWatcher;
  final _debouncer = Debouncer(milliseconds: 20000);

  FvmCacheProvider({
    this.ref,
    List<LocalVersion> initialState,
  }) : super(initialState) {
    reloadState();
    // Load State again while listening to directory
    directoryWatcher = Watcher(fvm_constants.kFvmHome).events.listen((event) {
      _debouncer.run(reloadState);
    });
  }

  Future<void> _setTotalCacheSize() async {
    final stat = await getDirectorySize(fvm_constants.kVersionsDir.path);
    ref.read(fvmCacheSizeProvider).state = stat.friendlySize;
  }

  Future<void> reloadState() async {
    // Cancel debounce to avoid running twice with no new state change
    _debouncer.cancel();
    final localVersions = await LocalVersionRepo.getAll();
    state = localVersions;

    channels = localVersions.where((item) => item.isChannel).toList();
    versions = localVersions.where((item) => item.isChannel == false).toList();
    _setTotalCacheSize();
  }

  LocalVersion getChannel(String name) {
    return channels.firstWhere(
      (c) => c.name == name,
      orElse: () => null,
    );
  }

  LocalVersion getVersion(String name) {
    // ignore: avoid_function_literals_in_foreach_calls
    return versions.firstWhere(
      (v) => v.name == name,
      orElse: () => null,
    );
  }

  @override
  void dispose() {
    directoryWatcher.cancel();
    super.dispose();
  }
}

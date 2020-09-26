import 'dart:collection';

import 'package:fvm_app/providers/fvm_cache.provider.dart';
import 'package:fvm_app/providers/projects_provider.dart';
import 'package:fvm_app/providers/settings.provider.dart';
import 'package:fvm_app/utils/notify.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fvm/fvm.dart';

import 'package:state_notifier/state_notifier.dart';

class FvmQueue {
  QueueItem activeItem;
  final Queue<QueueItem> queue;
  FvmQueue({@required this.activeItem, @required this.queue});

  bool get isEmpty {
    return queue.isEmpty;
  }

  QueueItem get next {
    activeItem = queue.removeFirst();
    return activeItem;
  }

  FvmQueue update() {
    return FvmQueue(activeItem: activeItem, queue: queue);
  }
}

class QueueItem {
  final String name;
  final QueueAction action;
  QueueItem({this.name, this.action});
}

enum QueueAction {
  setupOnly,
  install,
  installAndSetup,
  channelUpgrade,
  remove,
}

/// Releases Provider
final fvmQueueProvider = StateNotifierProvider<FvmQueueProvider>((ref) {
  return FvmQueueProvider(ref: ref);
});

class FvmQueueProvider extends StateNotifier<FvmQueue> {
  final ProviderReference ref;
  FvmQueueProvider({@required this.ref}) : super(null) {
    state = FvmQueue(activeItem: null, queue: Queue());
  }

  Settings get settings {
    return ref.read(settingsProvider.state);
  }

  void install(String version, {bool skipSetup = true}) async {
    final action =
        settings.skipSetup ? QueueAction.install : QueueAction.installAndSetup;
    _addToQueue(version, action: action);
    runQueue();
  }

  void setup(String version) {
    _addToQueue(version, action: QueueAction.setupOnly);
    runQueue();
  }

  void upgrade(String version) {
    _addToQueue(version, action: QueueAction.channelUpgrade);
    runQueue();
  }

  void remove(String version) {
    _addToQueue(version, action: QueueAction.remove);
    runQueue();
  }

  void runQueue() async {
    final queue = state.queue;
    final activeItem = state.activeItem;
    // No need to run if empty
    if (queue.isEmpty) return;
    // If currently installing a version
    if (activeItem != null) return;
    // Gets next item of the queue
    final item = state.next;
    // Update queue
    state = state.update();

    // Run through actions
    switch (item.action) {
      case QueueAction.install:
        await FVM.install(item.name);
        notify('Version ${item.name} has been installed');
        break;
      case QueueAction.setupOnly:
        await FVM.setup(item.name);
        await notify('Version ${item.name} has finished setup.');
        await _checkAndDisableAnalytics(item.name);
        notify('Version ${item.name} has finished setup');

        break;
      case QueueAction.installAndSetup:
        await FVM.install(item.name);
        await FVM.setup(item.name);
        await notify('Version ${item.name} has been installed');
        await _checkAndDisableAnalytics(item.name);
        break;
      case QueueAction.channelUpgrade:
        await FVM.upgrade(item.name);
        notify('Channel ${item.name} has been upgraded');
        break;
      case QueueAction.remove:
        await FVM.remove(item.name);
        notify('Version ${item.name} has been removed');
        break;
      default:
        break;
    }
    // Check if action is to setup only

    // Set active item to null
    state.activeItem = null;
    // Run update on cache
    await ref.read(fvmCacheProvider).reloadState();
    // Update queue
    state = state.update();

    // Run queue again
    runQueue();
  }

  Future<void> pinVersion(FlutterProject project, String version) async {
    await FlutterProjectRepo.pinVersion(project, version);
    await ref.read(projectsProvider).reloadOne(project);
    await notify('Version $version pinned to ${project.name}');
  }

  Future<void> _addToQueue(String version, {QueueAction action}) async {
    state.queue.add(QueueItem(name: version, action: action));
    state = state.update();
  }

  Future<void> _checkAndDisableAnalytics(String version) async {
    if (settings.noAnalytics) {
      await FVM.noAnalytics(version);
    }
  }
}

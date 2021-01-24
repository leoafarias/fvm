// Get path of the directory to find
// Look recursively to all records and get if they have an FVM config
// If they do have fvm config get pubspec, and project name
// Get information about the config and match with the release
// Allow to change the version on a project
// When deleting a version notify that a project has that version attached to it

import 'dart:io';

import 'package:fvm_app/providers/settings.provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fvm/fvm.dart';
import 'package:state_notifier/state_notifier.dart';

final projectsScanProvider = FutureProvider<List<FlutterProject>>((ref) {
  final settings = ref.watch(settingsProvider.state);
  if (settings.flutterProjectsDir == null) {
    throw Exception('A Flutter Projects directory must be selected');
  } else {
    return FlutterProjectRepo.scanDirectory();
  }
});

// ignore: top_level_function_literal_block
final projectsPerVersionProvider = Provider((ref) {
  final list = <String, List<FlutterProject>>{};
  final projects = ref.watch(projectsProvider.state);

  if (projects == null || projects.list.isEmpty) {
    return list;
  }

  for (var project in projects.list) {
    final version =
        project.pinnedVersion != null ? project.pinnedVersion : 'NONE';
    final versionProjects = list[version];
    if (versionProjects != null) {
      versionProjects.add(project);
    } else {
      list[version] = [project];
    }
  }

  return list;
});

final projectsProvider = StateNotifierProvider<ProjectsProvider>((ref) {
  return ProjectsProvider(ref);
});

class ProjectsProviderState {
  List<FlutterProject> list;
  bool loading;
  String error;

  ProjectsProviderState({
    this.list = const [],
    this.loading = false,
    this.error,
  });

  factory ProjectsProviderState.loading() {
    return ProjectsProviderState(loading: true);
  }

  factory ProjectsProviderState.error(dynamic err) {
    return ProjectsProviderState(error: err.toString());
  }
}

class ProjectsProvider extends StateNotifier<ProjectsProviderState> {
  final ProviderReference ref;

  ProjectsProvider(this.ref) : super(ProjectsProviderState()) {
    reloadAll();
  }

  SettingsProvider get _settings {
    return ref.read<SettingsProvider>(settingsProvider);
  }

  Future<void> scan() async {
    final settings = await _settings.read();
    // Return if there is no directory to scan
    if (settings.flutterProjectsDir == null) {
      return;
    }
    final projects = await FlutterProjectRepo.scanDirectory(
      rootDir: Directory(settings.flutterProjectsDir),
    );
    // Set project paths
    settings.projectPaths = projects.map((project) {
      return project.projectDir.path;
    }).toList();
    await _settings.save(settings);
    await reloadAll();
  }

  Future<void> pinVersion(FlutterProject project, String version) async {
    await FlutterProjectRepo.pinVersion(project, version);
    await reloadOne(project);
  }

  Future<void> reloadAll() async {
    state.loading = true;
    final settings = await _settings.read();
    if (settings.projectPaths == null) {}
    final directories = settings.projectPaths.map((path) => path).toList();
    state.list = await FlutterProjectRepo.fetchProjects(directories);
    state = state;
    state.loading = false;
  }

  Future<void> reloadOne(FlutterProject project) async {
    final index = state.list.indexWhere((item) => item == project);

    state.list[index] = await FlutterProjectRepo.getOne(project.projectDir);
    state = state;
  }
}

import 'package:fvm_app/providers/projects_provider.dart';
import 'package:hooks_riverpod/all.dart';

final projectDependenciesProvider = FutureProvider((ref) {
  final projects = ref.watch(projectsProvider.state);

  for (var project in projects.list) {
    final pubspec = project.pubspec;
    final deps = pubspec.dependencies.toList();
    final devDeps = pubspec.devDependencies.toList();
    final allDeps = [...deps, ...devDeps];

    for (var dep in allDeps) {}
  }
});

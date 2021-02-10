import 'package:fvm_app/providers/projects_provider.dart';
import 'package:fvm_app/utils/dependencies.dart';
import 'package:fvm_app/utils/http_cache.dart';
import 'package:github/github.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:hooks_riverpod/all.dart';

final getGithubRepositoryProvider =
    FutureProvider.family<Repository, RepositorySlug>((ref, repoSlug) async {
  final github = GitHub(
    auth: Authentication.withToken('fa01cbd4098cb70784d31b8383e32f7f68ee9526'),
    client: CacheHttpClient(),
  );
  if (repoSlug == null) {
    throw 'Not valid Github Slug';
  }
  return await github.repositories.getRepository(repoSlug);
});

// ignore: top_level_function_literal_block
final projectDependenciesProvider = FutureProvider((ref) async {
  final projects = ref.watch(projectsProvider.state);
  final packages = <String, int>{};

  for (var project in projects.list) {
    final pubspec = project.pubspec;
    final deps = pubspec.dependencies.toList();
    final devDeps = pubspec.devDependencies.toList();
    final allDeps = [...deps, ...devDeps];

    // Loop through all dependencies
    // ignore: avoid_function_literals_in_foreach_calls
    allDeps.forEach((dep) {
      // ignore: invalid_use_of_protected_member
      if (dep.hosted != null && !isGooglePubPackage(dep.package())) {
        packages.update(dep.package(), (val) => ++val, ifAbsent: () => 1);
      }
    });
  }
  final pkgs = await fetchAllDependencies(packages);
  pkgs..sort((a, b) => a.compareTo(b));
  // Reverse order
  return pkgs.reversed.toList();
});

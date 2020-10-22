import 'package:fvm_app/components/atoms/list_tile.dart';
import 'package:fvm_app/components/atoms/screen.dart';
import 'package:fvm_app/components/molecules/package_score_display.dart';

import 'package:fvm_app/providers/project_dependencies.provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PackagesScreen extends HookWidget {
  const PackagesScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final packages = useProvider(projectDependenciesProvider);

    return packages.when(
        data: (data) {
          return FvmScreen(
            title: 'On The Shoulders of Giants (Used Packages)',
            child: ListView.separated(
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final pkg = data[index];
                return Container(
                  height: 90,
                  child: Center(
                    child: FvmListTile(
                      title: Text(pkg.package.name),
                      subtitle: Text(
                        pkg.package.description,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.caption,
                      ),
                      trailing: PackageScoreDisplay(score: pkg.score),
                    ),
                  ),
                );
              },
              itemCount: data.length,
            ),
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => Container());
  }
}

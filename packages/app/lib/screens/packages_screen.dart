import 'package:fvm_app/components/atoms/screen.dart';
import 'package:fvm_app/providers/projects_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PackagesScreen extends HookWidget {
  const PackagesScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projects = useProvider(projectsProvider.state);

    if (projects.loading || projects.list.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final project = projects.list[0];

    return FvmScreen(
      title: 'Packages Screen',
      child: Container(
          child: Column(
        children: [
          Text(project.name),
          ListView.builder(
            shrinkWrap: true,
            itemCount: project.pubspec.dependencies.length,
            itemBuilder: (context, index) {
              final dep = project.pubspec.dependencies.toList()[index];
              return ListTile(
                title: Text(dep.package()),
              );
            },
          )
        ],
      )),
    );
  }
}

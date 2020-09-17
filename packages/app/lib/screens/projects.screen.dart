import 'package:fvm_app/components/atoms/loading_indicator.dart';
import 'package:fvm_app/components/atoms/screen.dart';
import 'package:fvm_app/utils/notify.dart';
import 'package:fvm_app/utils/prune_versions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:fvm_app/components/molecules/empty_data_set/empty_projects.dart';
import 'package:fvm_app/components/molecules/project_item.dart';
import 'package:fvm_app/providers/projects_provider.dart';

class ProjectsScreen extends HookWidget {
  const ProjectsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projects = useProvider(projectsProvider.state);
    final controller = useScrollController();

    if (projects.loading) {
      return const Center(
        child: LoadingIndicator(),
      );
    }

    if (projects.list.isEmpty) {
      return const EmptyProjects();
    }

    return FvmScreen(
      title: 'Flutter Projects',
      actions: [
        IconButton(
          tooltip: 'Refresh Projects',
          icon: const Icon(MdiIcons.refresh, size: 20),
          onPressed: () async {
            await context.read(projectsProvider).scan();
            notify('Projects Refreshed');
          },
        ),
      ],
      child: Scrollbar(
        child: ListView.builder(
          controller: controller,
          itemCount: projects.list.length,
          itemBuilder: (context, index) {
            final item = projects.list[index];
            return ProjectItem(item, key: Key(item.projectDir.path));
          },
        ),
      ),
    );
  }
}

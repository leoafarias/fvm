import 'package:fvm_app/components/atoms/loading_indicator.dart';
import 'package:fvm_app/components/atoms/screen.dart';
import 'package:fvm_app/components/atoms/typography.dart';
import 'package:fvm_app/providers/settings.provider.dart';
import 'package:fvm_app/utils/notify.dart';

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
    final filteredProjects = useState(projects.list);
    final settings = useProvider(settingsProvider.state);

    final controller = useScrollController();

    useEffect(() {
      if (settings.onlyProjectsWithFvm) {
        filteredProjects.value =
            projects.list.where((p) => p.pinnedVersion != null).toList();
      } else {
        filteredProjects.value = projects.list;
      }
      return;
    }, [projects, settings.onlyProjectsWithFvm]);

    if (projects.loading) {
      return const Center(
        child: LoadingIndicator(),
      );
    }

    if (filteredProjects.value.isEmpty) {
      return const EmptyProjects();
    }

    return FvmScreen(
      title: 'Flutter Projects',
      actions: [
        FlatButton.icon(
          label: const TypographyCaption('Refresh'),
          icon: const Icon(MdiIcons.refresh, size: 20),
          onPressed: () async {
            await context.read(projectsProvider).scan();
            notify('Projects Refreshed');
          },
        ),
        const VerticalDivider(
          width: 40,
        ),
        Tooltip(
          message: '''Displays only projects with versions pinned.''',
          child: Row(
            children: [
              const TypographyCaption('Only Pinned'),
              SizedBox(
                height: 10,
                width: 60,
                child: Switch(
                  activeColor: Colors.cyan,
                  value: settings.onlyProjectsWithFvm,
                  onChanged: (active) async {
                    settings.onlyProjectsWithFvm = active;
                    await context.read(settingsProvider).save(settings);
                  },
                ),
              ),
            ],
          ),
        )
      ],
      child: Scrollbar(
        child: ListView.builder(
          controller: controller,
          itemCount: filteredProjects.value.length,
          itemBuilder: (context, index) {
            final item = filteredProjects.value[index];
            return ProjectItem(item, key: Key(item.projectDir.path));
          },
        ),
      ),
    );
  }
}

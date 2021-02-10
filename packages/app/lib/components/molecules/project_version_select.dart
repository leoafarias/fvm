import 'package:fvm_app/components/atoms/typography.dart';
import 'package:fvm_app/providers/fvm_queue.provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fvm/fvm.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:fvm_app/dto/version.dto.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ProjectVersionSelect extends HookWidget {
  final FlutterProject project;
  final List<VersionDto> versions;

  const ProjectVersionSelect({
    @required this.project,
    @required this.versions,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final projects = useProvider(projectsProvider);
    final isInstalled = useState(false);

    void checkIfInstalled() {
      if (versions.isEmpty) return;
      final hasVersion = versions.firstWhere(
        (version) => project.pinnedVersion == version.name,
        orElse: () => null,
      );

      isInstalled.value = hasVersion != null;
    }

    // ignore: unnecessary_lambdas
    useEffect(() {
      checkIfInstalled();
      return;
    }, [versions]);

    return PopupMenuButton<String>(
        tooltip: 'Select a Flutter SDK Version',
        child: Container(
          height: 35,
          decoration: const BoxDecoration(
            color: Colors.white10,
          ),
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          // color: Colors.black38,
          constraints: const BoxConstraints(minWidth: 110, maxWidth: 165),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              project.pinnedVersion != null
                  ? TypographyCaption(project.pinnedVersion)
                  : const TypographyCaption('Choose'),
              const SizedBox(width: 20),
              const Icon(MdiIcons.chevronDown),
            ],
          ),
        ),
        onSelected: (version) async {
          context.read(fvmQueueProvider).pinVersion(project, version);
        },
        itemBuilder: (context) {
          return versions
              .map(
                (version) => PopupMenuItem(
                  value: version.name,
                  child: Text(version.name),
                ),
              )
              .toList();
        });
  }
}

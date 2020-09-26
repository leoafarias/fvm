import 'package:fvm_app/components/atoms/screen.dart';
import 'package:fvm_app/utils/prune_versions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:fvm_app/components/molecules/empty_data_set/empty_versions.dart';
import 'package:fvm_app/components/molecules/version_installed_item.dart';
import 'package:fvm_app/providers/installed_versions.provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HomeScreen extends HookWidget {
  const HomeScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final list = useProvider(installedVersionsProvider);

    if (list == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return const EmptyVersions();
    }

    return FvmScreen(
      title: 'Installed Versions',
      actions: [
        Tooltip(
          message: 'Clean up unused versions.',
          child: IconButton(
            icon: const Icon(MdiIcons.broom, size: 20),
            onPressed: () async {
              await pruneVersionsDialog(context);
            },
          ),
        )
      ],
      child: Scrollbar(
        child: ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, index) {
            return VersionInstalledItem(list[index]);
          },
        ),
      ),
    );
  }
}

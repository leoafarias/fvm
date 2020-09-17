import 'package:fvm_app/providers/selected_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:fvm_app/components/molecules/delete_dialog.dart';
import 'package:fvm_app/dto/version.dto.dart';
import 'package:fvm_app/providers/fvm_queue.provider.dart';

enum InstalledActions { remove, detail }

class VersionInstalledActions extends StatelessWidget {
  final VersionDto version;
  const VersionInstalledActions(this.version, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (version == null) {
      return const SizedBox(height: 0);
    }
    return PopupMenuButton<InstalledActions>(
      onSelected: (result) {
        if (result == InstalledActions.remove) {
          showDeleteDialog(context, item: version, onDelete: () {
            context.read(fvmQueueProvider).remove(version.name);
          });
        }

        if (result == InstalledActions.detail) {
          context.read(selectedInfoProvider).selectVersion(version);
        }
      },
      child: const Icon(MdiIcons.dotsVertical),
      itemBuilder: (context) {
        return <PopupMenuEntry<InstalledActions>>[
          const PopupMenuItem(
            value: InstalledActions.detail,
            child: Text('Details'),
          ),
          const PopupMenuItem(
            value: InstalledActions.remove,
            child: Text('Remove'),
          ),
        ];
      },
    );
  }
}

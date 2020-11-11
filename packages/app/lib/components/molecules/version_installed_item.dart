import 'package:fvm_app/components/atoms/typography.dart';
import 'package:fvm_app/providers/selected_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fvm_app/components/atoms/list_tile.dart';
import 'package:fvm_app/components/atoms/version_installed_status.dart';
import 'package:fvm_app/components/molecules/version_installed_actions.dart';
import 'package:fvm_app/dto/version.dto.dart';

class VersionInstalledItem extends StatelessWidget {
  final VersionDto version;

  const VersionInstalledItem(
    this.version, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FvmListTile(
      leading: version.isChannel
          ? const Icon(MdiIcons.alphaCCircle)
          : const Icon(MdiIcons.alphaRCircle),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TypographySubheading(version.name),
          VersionInstalledStatus(version),
        ],
      ),
      trailing: VersionInstalledActions(version),
      onTap: () {
        context.read(selectedInfoProvider).selectVersion(version);
      },
    );
  }
}

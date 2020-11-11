import 'package:fvm_app/components/atoms/cache_date_display.dart';
import 'package:fvm_app/components/atoms/copy_button.dart';
import 'package:fvm_app/components/atoms/group_tile.dart';
import 'package:fvm_app/components/atoms/list_tile.dart';
import 'package:fvm_app/components/atoms/typography.dart';
import 'package:fvm_app/dto/version.dto.dart';
import 'package:flutter/material.dart';

class CacheInfoTile extends StatelessWidget {
  final VersionDto version;
  const CacheInfoTile(this.version, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!version.isInstalled) {
      return const SizedBox(height: 0);
    }
    return FvmGroupListTile(
      title: const Text('Local Cache Information'),
      children: [
        FvmListTile(
          title: const Text('Created Date'),
          trailing: CacheDateDisplay(version),
        ),
        const Divider(height: 0),
        FvmListTile(
          title: const Text('Cache Location'),
          subtitle: TypographyCaption(version.installedDir.path),
          trailing: CopyButton(version.installedDir.path),
        ),
      ],
    );
  }
}

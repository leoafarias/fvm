import 'package:fvm_app/components/atoms/cache_date_display.dart';
import 'package:fvm_app/components/atoms/copy_button.dart';
import 'package:fvm_app/components/atoms/group_tile.dart';
import 'package:fvm_app/components/atoms/list_tile.dart';
import 'package:fvm_app/components/atoms/typography.dart';
import 'package:fvm_app/dto/version.dto.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdvancedInfoTile extends StatelessWidget {
  final VersionDto version;
  const AdvancedInfoTile(this.version, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (version.release == null) {
      return const SizedBox(height: 0);
    }

    return FvmGroupListTile(
      title: const Text('Advanced'),
      children: [
        FvmListTile(
          title: const Text('Download Zip'),
          subtitle: const FvmCaption('Zip file with all release dependencies.'),
          trailing: IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: () async {
              if (await canLaunch(version.release.archiveUrl)) {
                await launch(version.release.archiveUrl);
              } else {
                throw '''Could not launch ${version.release.archiveUrl}''';
              }
            },
          ),
        ),
        const Divider(),
        FvmListTile(
          title: const Text('Hash'),
          subtitle: FvmCaption(version.release.hash),
          trailing: CopyButton(version.release.hash),
        ),
        const Divider(),
        FvmListTile(
          title: const Text('Sha256'),
          subtitle: FvmCaption(version.release.sha256),
          trailing: CopyButton(version.release.sha256),
        ),
      ],
    );
  }
}

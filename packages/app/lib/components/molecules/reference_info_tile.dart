import 'package:fvm_app/components/atoms/list_tile.dart';
import 'package:fvm_app/components/atoms/setup_button.dart';
import 'package:fvm_app/components/atoms/typography.dart';
import 'package:fvm_app/dto/channel.dto.dart';
import 'package:fvm_app/dto/version.dto.dart';
import 'package:fvm_app/utils/channel_descriptions.dart';
import 'package:flutter/material.dart';

class ReferenceInfoTile extends StatelessWidget {
  final VersionDto version;
  const ReferenceInfoTile(this.version, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Display channell reference if it's a release
    if (!version.isChannel) {
      return FvmListTile(
        title: const Text('Channel'),
        trailing: Chip(label: Text(version.release.channelName)),
      );
    }

    final channel = version as ChannelDto;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: TypographyParagraph(channelDescriptions[version.name]),
        ),
        const Divider(height: 0),
        FvmListTile(
          title: const Text('Version'),
          trailing: channel.sdkVersion != null
              ? Chip(label: Text(channel.sdkVersion ?? ''))
              : SetupButton(version: channel),
        )
      ],
    );
  }
}

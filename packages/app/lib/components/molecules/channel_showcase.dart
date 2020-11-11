import 'package:fvm_app/components/atoms/typography.dart';
import 'package:fvm_app/components/molecules/version_install_button.dart';
import 'package:fvm_app/dto/channel.dto.dart';
import 'package:fvm_app/providers/selected_info_provider.dart';

import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChannelShowcase extends StatelessWidget {
  final ChannelDto channel;
  const ChannelShowcase(this.channel, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      onPressed: () {
        context.read(selectedInfoProvider).selectVersion(channel);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TypographyTitle(channel.name),
                TypographySubheading(channel.release.version),
                const SizedBox(height: 5),
                TypographyCaption(
                  DateTimeFormat.relative(
                    channel.release.releaseDate,
                    appendIfAfter: 'ago',
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                VersionInstallButton(channel),
              ],
            )
          ],
        ),
      ),
    );
  }
}

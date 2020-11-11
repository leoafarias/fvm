import 'package:fvm_app/components/atoms/sliver_app_bar_title.dart';
import 'package:fvm_app/components/atoms/typography.dart';
import 'package:fvm_app/components/molecules/channel_showcase.dart';
import 'package:fvm_app/components/molecules/version_install_button.dart';
import 'package:fvm_app/components/molecules/version_item.dart';
import 'package:fvm_app/providers/channels.provider.dart';

import 'package:fvm_app/providers/filterable_releases.provider.dart';
import 'package:fvm_app/providers/master.provider.dart';
import 'package:fvm_app/providers/settings.provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fvm/fvm.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fvm_app/utils/extensions.dart';

class ExploreScreen extends HookWidget {
  const ExploreScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filter = useProvider(filterProvider);
    final releases = useProvider(filterableReleasesProvider);
    final channels = useProvider(channelsProvider);
    final master = useProvider(masterProvider);
    final settings = useProvider(settingsProvider.state);

    final channelKeys = channelValues.map.keys.toList();
    // Add all filter
    channelKeys.add('All');
    channelKeys.sort();

    if (releases == null || channels.all.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Scrollbar(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const TypographyTitle('Channels'),
              actions: [
                Tooltip(
                  message:
                      '''Allows access to functionality that is unsable, and latest cutting edge.''',
                  child: Row(
                    children: [
                      const TypographyCaption('Advanced'),
                      SizedBox(
                        height: 10,
                        width: 60,
                        child: Switch(
                          activeColor: Colors.cyan,
                          value: settings.advancedMode,
                          onChanged: (active) async {
                            settings.advancedMode = active;
                            await context.read(settingsProvider).save(settings);
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
              centerTitle: false,
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 0),
              ),
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: settings.advancedMode ? 80 : 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.deepOrange,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        const TypographySubheading('Master'),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: TypographyCaption(
                              '''The current tip-of-tree, absolute latest cutting edge build. Usually functional, though sometimes we accidentally break things.'''),
                        ),
                        const SizedBox(width: 20),
                        VersionInstallButton(master),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 120.0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              pinned: true,
              excludeHeaderSemantics: true,
              actions: [Container()],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: channels.all.map((channel) {
                    return Expanded(child: ChannelShowcase(channel));
                  }).toList(),
                ),
              ),
              title: SliverAppBarSwitcher(
                child: Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: channels.all.map((channel) {
                      return Expanded(child: VersionItem(channel));
                    }).toList(),
                  ),
                ),
              ),
            ),
            SliverAppBar(
              pinned: true,
              toolbarHeight: 50,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 0),
              ),
              automaticallyImplyLeading: false,
              actions: [Container()],
              title: Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const TypographyTitle('Versions'),
                        const SizedBox(width: 10),
                        Chip(label: Text(releases.length.toString())),
                      ],
                    ),
                    DropdownButton<String>(
                      value: channelValues.reverse[filter.state] ?? 'All',
                      icon: const Icon(Icons.filter_list),
                      underline: Container(),
                      items: channelKeys.map((key) {
                        return DropdownMenuItem(
                            value: key, child: Text(key.capitalize()));
                      }).toList(),
                      onChanged: (newValue) {
                        filter.state = channelValues.map[newValue];
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return VersionItem(releases[index]);
              }, childCount: releases.length),
            ),
          ],
        ),
      ),
    );
  }
}

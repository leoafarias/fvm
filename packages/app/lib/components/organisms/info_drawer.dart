import 'package:fvm_app/components/atoms/typography.dart';

import 'package:fvm_app/components/molecules/cache_info_tile.dart';
import 'package:fvm_app/components/molecules/reference_info_tile.dart';
import 'package:fvm_app/components/molecules/release_info_section.dart';
import 'package:fvm_app/components/molecules/version_install_button.dart';
import 'package:fvm_app/providers/selected_info_provider.dart';

import 'package:fvm_app/utils/layout_size.dart';

import 'package:flutter/material.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class InfoDrawer extends HookWidget {
  const InfoDrawer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = useProvider(selectedInfoProvider);
    final selectedState = useProvider(selectedInfoProvider.state);

    final selected = selectedState.version;

    void onClose() {
      // Close drawer if its not large layout
      if (!LayoutSize.isLarge) {
        Navigator.pop(context);
      }
      provider.clearVersion();
    }

    if (selected == null) {
      return Drawer(
        child: Container(
          color: Theme.of(context).cardColor,
          child: const Center(child: TypographyCaption('Nothing selected')),
        ),
      );
    }

    return Drawer(
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: AppBar(
          title: TypographyTitle(selected.name),
          leading: IconButton(
            icon: const Icon(Icons.close),
            iconSize: 20,
            splashRadius: 20,
            onPressed: onClose,
          ),
          shadowColor: Colors.transparent,
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.all(0),
          child: VersionInstallButton(
            selected,
            expanded: true,
          ),
        ),
        body: Scrollbar(
          child: ListView(
            children: [
              ReferenceInfoTile(selected),
              CacheInfoTile(selected),
              ReleaseInfoSection(selected)
            ],
          ),
        ),
      ),
    );
  }
}

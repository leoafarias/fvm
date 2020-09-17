import 'package:fvm_app/components/atoms/screen.dart';
import 'package:fvm_app/providers/projects_provider.dart';
import 'package:fvm_app/providers/settings.provider.dart';
import 'package:fvm_app/utils/notify.dart';
import 'package:file_chooser/file_chooser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsScreen extends HookWidget {
  const SettingsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = useProvider(settingsProvider);
    final settings = useProvider(settingsProvider.state);
    final projects = useProvider(projectsProvider);
    final prevProjectsDir = usePrevious(settings.flutterProjectsDir);

    Future<void> handleSave() async {
      try {
        await provider.save(settings);
        if (prevProjectsDir != settings.flutterProjectsDir) {
          await projects.scan();
        }
        notify('Settings have been saved');
      } on Exception {
        notifyError('Could not refresh projects');
        settings.flutterProjectsDir = prevProjectsDir;
        await provider.save(settings);
      }
    }

    return FvmScreen(
      title: 'Settings',
      child: SettingsList(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        sections: [
          SettingsSection(
            tiles: [
              SettingsTile(
                title: 'Flutter Projects',
                subtitle: settings.flutterProjectsDir,
                leading: const Icon(MdiIcons.folderHome),
                subtitleTextStyle: Theme.of(context).textTheme.caption,
                onTap: () async {
                  final fileResult = await showOpenPanel(
                    allowedFileTypes: [],
                    canSelectDirectories: true,
                  );

                  // Save if a path is selected
                  if (fileResult.paths.isNotEmpty) {
                    settings.flutterProjectsDir = fileResult.paths.single;
                  }

                  await handleSave();
                },
              ),
              SettingsTile.switchTile(
                title: 'Disable tracking',
                subtitle: """
This will disable Google's crash reporting and analytics, when installing a new version.""",
                leading: const Icon(MdiIcons.bug),
                switchActiveColor: Theme.of(context).accentColor,
                switchValue: settings.noAnalytics ?? false,
                subtitleTextStyle: Theme.of(context).textTheme.caption,
                onToggle: (value) async {
                  settings.noAnalytics = value;
                  await handleSave();
                },
              ),
              SettingsTile.switchTile(
                title: 'Skip setup Flutter on install',
                subtitle:
                    """This will only clone Flutter and not install dependencies after a new version is installed.""",
                leading: const Icon(MdiIcons.cogSync),
                switchActiveColor: Theme.of(context).accentColor,
                subtitleTextStyle: Theme.of(context).textTheme.caption,
                switchValue: settings.skipSetup ?? false,
                onToggle: (value) async {
                  settings.skipSetup = value;
                  await handleSave();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

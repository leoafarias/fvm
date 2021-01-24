import 'package:fvm_app/constants.dart';
import 'package:fvm_app/dto/channel.dto.dart';
import 'package:fvm_app/dto/master.dto.dart';
import 'package:fvm_app/dto/release.dto.dart';

import 'package:fvm_app/providers/fvm_cache.provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fvm/fvm.dart';

class AppReleasesState {
  List<ChannelDto> channels;
  List<ChannelDto> installedChannels;
  List<ReleaseDto> versions;
  List<ReleaseDto> installedVersions;
  MasterDto master;
  AppReleasesState({
    this.channels,
    this.installedChannels,
    this.versions,
    this.installedVersions,
    this.master,
  }) {
    channels = <ChannelDto>[];
    installedChannels = <ChannelDto>[];
    versions = <ReleaseDto>[];
    installedVersions = <ReleaseDto>[];
  }
}

final flutterReleasesProvider =
    FutureProvider<FlutterReleases>((_) => FVM.getFlutterReleases());

// ignore: top_level_function_literal_block
final releasesStateProvider = Provider<AppReleasesState>((ref) {
  // Filter only version that are valid releases
  var payload = FlutterReleases();
  ref.watch(flutterReleasesProvider).whenData((value) => payload = value);
  final installedVersions = ref.watch(fvmCacheProvider);

  // Watch this state change for refresh
  ref.watch(fvmCacheProvider.state);

  final flutterReleases = payload.releases;
  final flutterChannels = payload.channels;

  //Creates empty releases starte
  final releasesState = AppReleasesState();

  if (flutterReleases == null || installedVersions == null) {
    return releasesState;
  }

  // Set Master separetely because workflow is very different
  final masterInstalled = installedVersions.getChannel(kMasterChannel);
  final masterVersion =
      masterInstalled != null ? masterInstalled.sdkVersion : null;

  releasesState.master = MasterDto(
    name: kMasterChannel,
    isInstalled: masterInstalled != null,
    needSetup: masterVersion == null,
    sdkVersion: masterVersion,
  );

  // Loop through available channels NOT including master
  for (var name in kAvailableChannels) {
    final latestRelease = flutterChannels[name];
    final installedChannel = installedVersions.getChannel(name);
    final sdkVersion =
        installedChannel == null ? null : installedChannel.sdkVersion;
    final channelDto = ChannelDto(
      name: name,
      isInstalled: installedChannel != null,
      needSetup: sdkVersion == null,
      sdkVersion: sdkVersion,
      // Get version for the channel
      currentRelease: payload.getReleaseFromVersion(sdkVersion),
      release: latestRelease,
    );

    releasesState.channels.add(channelDto);
    if (channelDto.isInstalled) {
      releasesState.installedChannels.add(channelDto);
    }
  }

  for (var item in flutterReleases) {
    if (item == null) return null;

    // Check if version is found in installed versions
    final installedVersion = installedVersions.getVersion(item.version);
    final sdkVersion = installedVersion?.sdkVersion;

    final version = ReleaseDto(
      name: item.version,
      release: item,
      isInstalled: installedVersion != null,
      needSetup: sdkVersion == null,
    );

    releasesState.versions.add(version);
    if (version.isInstalled) {
      releasesState.installedVersions.add(version);
    }
  }

  return releasesState;
});

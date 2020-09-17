import 'package:fvm_app/dto/channel.dto.dart';
import 'package:fvm_app/providers/flutter_releases.provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fvm/fvm.dart';

class ChannelsProviderPayload {
  final List<ChannelDto> all;
  final ChannelDto beta;
  final ChannelDto dev;
  final ChannelDto stable;

  ChannelsProviderPayload({
    this.all,
    this.beta,
    this.dev,
    this.stable,
  });
}

ChannelsProviderPayload _mapChannels(List<ChannelDto> list) {
  ChannelDto beta;
  ChannelDto dev;
  ChannelDto stable;
  final all = <ChannelDto>[];

  for (var item in list) {
    switch (item.release.channel) {
      case Channel.beta:
        beta = item;
        all.add(beta);
        break;
      case Channel.dev:
        dev = item;
        all.add(dev);
        break;
      case Channel.stable:
        stable = item;
        // Add Stable as first element for correct ordering
        all.insert(0, stable);
        break;
      default:
    }
  }

  return ChannelsProviderPayload(
    all: all,
    beta: beta,
    dev: dev,
    stable: stable,
  );
}

/// Channels Provider
// ignore: top_level_function_literal_block
final channelsProvider = Provider((ref) {
  final provider = ref.watch(releasesStateProvider);
  return _mapChannels(provider.channels);
});

// ignore: top_level_function_literal_block
final installedChannelsProvider = Provider((ref) {
  final provider = ref.watch(releasesStateProvider);
  return _mapChannels(provider.installedChannels);
});

import 'package:fvm_app/dto/release.dto.dart';
import 'package:fvm_app/providers/flutter_releases.provider.dart';
import 'package:fvm/fvm.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class ReleasesProviderPayload {
  final List<ReleaseDto> all;
  final List<ReleaseDto> beta;
  final List<ReleaseDto> dev;
  final List<ReleaseDto> stable;

  ReleasesProviderPayload({
    this.all,
    this.beta,
    this.dev,
    this.stable,
  });
}

ReleasesProviderPayload _mapVersions(List<ReleaseDto> list) {
  final beta = <ReleaseDto>[];
  final dev = <ReleaseDto>[];
  final stable = <ReleaseDto>[];
  for (var item in list) {
    if (item.release.channel == Channel.beta) {
      beta.add(item);
    }

    if (item.release.channel == Channel.dev) {
      dev.add(item);
    }

    if (item.release.channel == Channel.stable) {
      stable.add(item);
    }
  }

  return ReleasesProviderPayload(
    all: list,
    beta: beta,
    dev: dev,
    stable: stable,
  );
}

// ignore: top_level_function_literal_block
final installedReleasesProvider = Provider((ref) {
  final state = ref.watch(releasesStateProvider);
  return _mapVersions(state.installedVersions);
});

// ignore: top_level_function_literal_block
final releasesProvider = Provider((ref) {
  final state = ref.watch(releasesStateProvider);
  return _mapVersions(state.versions);
});

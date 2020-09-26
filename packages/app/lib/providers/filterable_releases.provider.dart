import 'package:fvm_app/dto/release.dto.dart';
import 'package:fvm_app/providers/releases.provider.dart';
import 'package:fvm/fvm.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final filterProvider = StateProvider<Channel>((_) => null);

// ignore: top_level_function_literal_block
final filterableReleasesProvider = Provider((ref) {
  final filter = ref.watch(filterProvider);
  final versions = ref.watch(releasesProvider);
  var releases = <ReleaseDto>[];

  switch (filter.state) {
    case Channel.stable:
      releases = versions.stable;
      break;
    case Channel.beta:
      releases = versions.beta;
      break;
    case Channel.dev:
      releases = versions.dev;
      break;
    default:
      releases = versions.all;
  }
  return releases;
});

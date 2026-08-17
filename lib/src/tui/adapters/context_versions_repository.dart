import '../../models/cache_flutter_version_model.dart';
import '../../models/flutter_version_model.dart';
import '../../services/cache_service.dart';
import '../../services/project_service.dart';
import '../../services/releases_service/models/flutter_releases_model.dart';
import '../../services/releases_service/releases_client.dart';
import '../../utils/helpers.dart';
import '../fvm_tui_models.dart';
import '../fvm_tui_ports.dart';
import 'fvm_context_handle.dart';

final class ContextVersionsRepository implements VersionsRepository {
  final FvmContextHandle contextHandle;

  const ContextVersionsRepository(this.contextHandle);

  @override
  Future<TuiVersionsData> load() async {
    final context = contextHandle.current;
    final cache = context.get<CacheService>();
    final items = await cache.getAllVersions();
    final releases = await context.get<FlutterReleaseClient>().fetchReleases();
    final global = cache.getGlobal();
    final project = context.get<ProjectService>().findVersion();
    final bytes = await getFullDirectorySize(items, context.get());

    return (
      items: items
          .map(
            (version) => mapVersionRow(
              version,
              releases: releases,
              global: global,
              project: project,
            ),
          )
          .toList(growable: false),
      cachePath: context.versionsCachePath,
      cacheBytes: bytes,
      updateMessage: buildChannelUpdateMessage(items, releases),
    );
  }
}

TuiVersionItem mapVersionRow(
  CacheFlutterVersion version, {
  required FlutterReleasesResponse releases,
  required CacheFlutterVersion? global,
  required String? project,
}) {
  final installedVersion = version.flutterSdkVersion ?? version.version;
  final release = releases.fromVersion(installedVersion);
  final channel =
      release?.channel.name ??
      version.releaseChannel?.name ??
      (version.isChannel ? version.name : 'release');
  final isGlobal =
      global != null &&
      _normalizeIdentity(global.nameWithAlias) ==
          _normalizeIdentity(version.nameWithAlias);
  final isProject =
      project != null &&
      _normalizeIdentity(project) == _normalizeIdentity(version.nameWithAlias);
  final metadata = <String>[
    if (version.dartSdkVersion case final dartVersion?) 'Dart $dartVersion',
    if (isGlobal) 'global',
    if (isProject) 'project',
    if (version.isNotSetup) 'setup required',
  ];

  return (
    id: version.nameWithAlias,
    version: installedVersion,
    channel: channel,
    metadata: metadata.join(' · '),
    installed: true,
    isGlobal: isGlobal,
    isProject: isProject,
    needsSetup: version.isNotSetup,
  );
}

String? buildChannelUpdateMessage(
  List<CacheFlutterVersion> versions,
  FlutterReleasesResponse releases,
) {
  final updates = <String>[];
  for (final version in versions) {
    if (!version.isChannel || version.isMain || version.fromFork) continue;
    final current = version.flutterSdkVersion;
    if (current == null) continue;
    final latest = releases.latestChannelRelease(version.name).version;
    if (!_isNewer(latest, current)) continue;
    updates.add('${version.name}: $current → $latest');
  }

  return updates.isEmpty ? null : updates.join(' · ');
}

String _normalizeIdentity(String value) {
  try {
    return FlutterVersion.parse(value).nameWithAlias;
  } on FormatException {
    return value.trim();
  }
}

bool _isNewer(String candidate, String current) {
  try {
    return FlutterVersion.parse(
          candidate,
        ).compareTo(FlutterVersion.parse(current)) >
        0;
  } on FormatException {
    return candidate != current;
  }
}

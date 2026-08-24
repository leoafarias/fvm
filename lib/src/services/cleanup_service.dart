import 'package:pub_semver/pub_semver.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/cleanup_model.dart';
import '../models/project_registry_model.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'project_registry_service.dart';
import 'project_service.dart';

/// Builds a cache cleanup plan from installed SDKs and known project usage.
///
/// Patch upgrades cover exact stable releases on the same fork and major/minor
/// line, and only when a project or the global setting still pins the older
/// SDK. Unused names then skip those recommended targets so a later `fvm use`
/// can still find them.
class CleanupService extends ContextualService {
  const CleanupService(super.context);

  List<PatchUpgrade> _patchUpgrades(
    List<CacheFlutterVersion> versions,
    CacheProjectUsage usage,
  ) {
    final candidatesByLine = <String, List<_PatchCandidate>>{};

    for (final cached in versions) {
      final candidate = _PatchCandidate.tryParse(cached);
      if (candidate == null) continue;
      candidatesByLine.putIfAbsent(candidate.line, () => []).add(candidate);
    }

    final ranked = <({PatchUpgrade upgrade, Version version})>[];
    for (final candidates in candidatesByLine.values) {
      candidates.sort((a, b) => b.version.compareTo(a.version));
      final latest = candidates.first;
      final toVersion = latest.cached.nameWithAlias;

      for (final candidate in candidates.skip(1)) {
        if (candidate.version == latest.version) continue;
        final fromVersion = candidate.cached.nameWithAlias;
        final actions = _upgradeActions(
          currentVersion: fromVersion,
          targetVersion: toVersion,
          usage: usage,
        );
        if (actions.isEmpty) continue;

        ranked.add(
          (
            upgrade: PatchUpgrade(
              fromVersion: fromVersion,
              toVersion: toVersion,
              reason:
                  'A newer cached patch release is available in the ${candidate.version.major}.${candidate.version.minor} line.',
              actions: actions,
            ),
            version: candidate.version,
          ),
        );
      }
    }

    ranked.sort((a, b) => b.version.compareTo(a.version));

    return [for (final item in ranked) item.upgrade];
  }

  List<CleanupAction> _upgradeActions({
    required String currentVersion,
    required String targetVersion,
    required CacheProjectUsage usage,
  }) {
    final actions = <CleanupAction>[];

    if (usage.globalVersion == currentVersion) {
      actions.add(CleanupAction(arguments: ['global', targetVersion]));
    }

    for (final reference in usage.referencesFor(currentVersion)) {
      actions.add(
        CleanupAction(
          arguments: [
            'use',
            targetVersion,
            if (reference.flavor != null) ...['--flavor', reference.flavor!],
          ],
          workingDirectory: reference.projectPath,
        ),
      );
    }

    return actions;
  }

  /// Cached patch upgrades to run by hand, and SDK names safe to remove.
  Future<({List<PatchUpgrade> upgrades, List<String> unused})> plan() async {
    final versions = await get<CacheService>().getAllVersions();
    final usage = get<ProjectRegistryService>().calculateUsage(
      includeCurrent: get<ProjectService>().tryFindAncestor(),
    );
    final upgrades = _patchUpgrades(versions, usage);
    // Keep recommended patch targets even when nothing pins them yet, so
    // `fvm cleanup --remove-unused` cannot delete the SDK an upgrade action
    // just told the user to switch to.
    final upgradeTargets = {
      for (final upgrade in upgrades) upgrade.toVersion,
    };
    final unused = [
      for (final version in versions)
        if (usage.isUnused(version.nameWithAlias) &&
            !upgradeTargets.contains(version.nameWithAlias))
          version.nameWithAlias,
    ]..sort();

    return (upgrades: upgrades, unused: unused);
  }
}

class _PatchCandidate {
  final CacheFlutterVersion cached;
  final Version version;

  const _PatchCandidate({required this.cached, required this.version});

  static _PatchCandidate? tryParse(CacheFlutterVersion cached) {
    if (!cached.isRelease || cached.releaseChannel != null) return null;

    final value = cached.version;
    final normalized = value.startsWith('v') ? value.substring(1) : value;
    final Version version;
    try {
      version = Version.parse(normalized);
    } on FormatException {
      return null;
    }
    if (version.preRelease.isNotEmpty || version.build.isNotEmpty) return null;

    return _PatchCandidate(cached: cached, version: version);
  }

  String get line => '${cached.fork ?? ''}|${version.major}.${version.minor}';
}

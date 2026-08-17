import '../../services/cache_service.dart';
import '../../services/releases_service/releases_client.dart';
import '../fvm_tui_models.dart';
import '../fvm_tui_ports.dart';
import 'fvm_context_handle.dart';

final class ContextReleasesRepository implements ReleasesRepository {
  final FvmContextHandle contextHandle;

  const ContextReleasesRepository(this.contextHandle);

  @override
  Future<List<TuiReleaseItem>> load() async {
    final context = contextHandle.current;
    final response = await context.get<FlutterReleaseClient>().fetchReleases();
    final installed = (await context.get<CacheService>().getAllVersions())
        .map((version) => version.flutterSdkVersion ?? version.name)
        .toSet();

    return response.versions.reversed
        .map(
          (release) => (
            version: release.version,
            channel: release.channel.name,
            releaseDate: release.releaseDate,
            dartSdkVersion: release.dartSdkVersion,
            architecture: release.dartSdkArch,
            activeChannel: release.activeChannel,
            installed: installed.contains(release.version),
          ),
        )
        .toList(growable: false);
  }
}

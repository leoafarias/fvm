part of '../tui_command.dart';

class FvmTuiVersionChoice {
  final String name;
  final String kind;
  final String channel;
  final String flutterVersion;
  final String dartVersion;
  final String releaseDate;
  final String cachePath;
  final String? alias;
  final bool isGlobal;
  final bool isProject;
  final bool needsSetup;

  const FvmTuiVersionChoice({
    required this.name,
    required this.kind,
    required this.channel,
    required this.flutterVersion,
    required this.dartVersion,
    required this.releaseDate,
    required this.cachePath,
    this.alias,
    this.isGlobal = false,
    this.isProject = false,
    this.needsSetup = false,
  });

  factory FvmTuiVersionChoice.fromCache(
    CacheFlutterVersion version, {
    FlutterReleasesResponse? releases,
    required bool isGlobal,
    required bool isProject,
  }) {
    final release = releases?.fromVersion(version.flutterSdkVersion ?? '');
    final channel = release?.channel.name ??
        version.releaseChannel?.name ??
        (version.isChannel ? '${version.name} channel' : version.type.name);
    final releaseDate =
        release == null ? '' : friendlyDate(release.releaseDate);

    return FvmTuiVersionChoice(
      name: version.nameWithAlias,
      kind: _kindLabel(version),
      channel: channel,
      flutterVersion: version.flutterSdkVersion ?? '',
      dartVersion: version.dartSdkVersion ?? '',
      releaseDate: releaseDate,
      cachePath: version.directory,
      isGlobal: isGlobal,
      isProject: isProject,
      needsSetup: version.isNotSetup,
    );
  }

  static String _kindLabel(CacheFlutterVersion version) {
    if (version.fromFork && version.isChannel) return 'forked channel';
    if (version.fromFork) return 'forked release';
    if (version.isChannel) return 'channel';
    if (version.isRelease) return 'release';
    if (version.isUnknownRef) return 'git ref';
    if (version.isCustom) return 'custom';

    return version.type.name;
  }

  static String _fitCells(String value, int maxCells) {
    if (value.isEmpty || maxCells <= 0) return '';
    if (terminalStringWidth(value) <= maxCells) return value;
    if (maxCells <= 3) return sliceByCells(value, maxCells);

    return '${sliceByCells(value, maxCells - 3)}...';
  }

  List<String> get statusTags => [
        if (isProject) 'project',
        if (isGlobal) 'global',
        if (needsSetup) 'needs setup',
        if (alias != null) 'alias $alias',
      ];

  String get statusSummary {
    if (statusTags.isEmpty) return 'ready';

    return statusTags.join(' | ');
  }

  String get healthLabel => needsSetup ? 'Needs setup' : 'Ready';

  String get titleLabel => _fitCells(name, 28);

  String get statusSummaryLabel => _fitCells(statusSummary, 28);

  String get cachePathLabel => _fitCells(cachePath, 20);

  String get rowLabel => _fitCells(name, 30);

  String get rowDescription {
    final rowTags = [
      if (isProject) 'project',
      if (isGlobal) 'global',
      if (needsSetup) 'needs setup',
    ].join('/');
    final details = [
      if (rowTags.isNotEmpty) rowTags,
      if (flutterVersion.isNotEmpty) 'Flutter $flutterVersion',
      if (dartVersion.isNotEmpty) 'Dart $dartVersion',
      channel,
    ].join(' | ');

    return _fitCells(details.isEmpty ? cachePath : details, 48);
  }
}

class _TuiCompletion {
  final FvmTuiVersionChoice? selected;

  const _TuiCompletion.selected(this.selected);

  const _TuiCompletion.cancelled() : selected = null;
}

// ignore_for_file: prefer-single-widget-per-file

import 'package:noir/noir.dart';

import '../fvm_tui_controller.dart';
import '../fvm_tui_models.dart';
import '../theme/fvm_tui_theme.dart';
import '../widgets/terminal_primitives.dart';

final class ReleasesScreen extends StatefulWidget {
  const ReleasesScreen({
    required this.controller,
    required this.layoutMode,
    this.onInstall,
    super.key,
  });

  final FvmTuiController controller;
  final FvmTuiLayoutMode layoutMode;
  final VoidCallback? onInstall;

  @override
  State<ReleasesScreen> createState() => ReleasesScreenState();
}

final class ReleasesScreenState extends State<ReleasesScreen> {
  var _controllerRevision = 0;
  var _showingDetail = false;

  bool get showingDetail => _showingDetail;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    if (mounted) setState(() => _controllerRevision += 1);
  }

  KeyEventResult _handleDetailKey(FocusNode node, KeyEvent event) {
    if (event.isPress && event.logicalKey == LogicalKeyboardKey.escape) {
      showList();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event.isPress && event.logicalKey == LogicalKeyboardKey.keyI) {
      widget.onInstall?.call();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _buildList(List<TuiReleaseItem> releases) => Select(
    options: releases
        .map(
          (release) => SelectOption(
            name: release.version,
            description: _description(release),
            value: release,
          ),
        )
        .toList(growable: false),
    selectedIndex: widget.controller.selectedReleaseIndex,
    height: 18,
    showScrollIndicator: true,
    color: FvmTuiColors.primary,
    backgroundColor: FvmTuiColors.surface,
    selectedBackgroundColor: FvmTuiColors.selected,
    selectedTextColor: FvmTuiColors.primary,
    descriptionColor: FvmTuiColors.muted,
    autofocus: true,
    onChanged: (index, option) => widget.controller.selectRelease(index),
    onSelect: (index, option) {
      widget.controller.selectRelease(index);
      if (widget.layoutMode == FvmTuiLayoutMode.compact) showDetail();
    },
  );

  Widget _buildDetail(List<TuiReleaseItem> releases) {
    final release = releases[widget.controller.selectedReleaseIndex];
    final detail = ReleaseDetail(release: release);
    if (widget.layoutMode == FvmTuiLayoutMode.wide) return detail;

    return Focus(autofocus: true, onKeyEvent: _handleDetailKey, child: detail);
  }

  void showDetail() {
    if (!mounted || _showingDetail) return;
    setState(() => _showingDetail = true);
  }

  void showList() {
    if (!mounted || !_showingDetail) return;
    setState(() => _showingDetail = false);
  }

  @override
  void didUpdateWidget(covariant ReleasesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.loading) {
      return Text('Loading releases…', style: FvmTuiTextStyles.muted);
    }
    final error = widget.controller.error;
    if (error != null) {
      return Text(
        'Could not load Flutter releases: $error',
        style: FvmTuiTextStyles.forTone(TuiTone.error),
      );
    }
    final releases = widget.controller.releases;
    if (releases == null || releases.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 1,
        children: [
          Text('No releases available', style: FvmTuiTextStyles.heading),
          Text(
            'Refresh after checking your network connection.',
            style: FvmTuiTextStyles.muted,
          ),
        ],
      );
    }
    final body = widget.layoutMode == FvmTuiLayoutMode.wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 2,
            children: [
              SizedBox(width: 40, child: _buildList(releases)),
              Expanded(child: _buildDetail(releases)),
            ],
          )
        : _showingDetail
        ? _buildDetail(releases)
        : _buildList(releases);

    return Focus(
      onKeyEvent: _handleKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 1,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Flutter releases', style: FvmTuiTextStyles.heading),
              Text(
                '${releases.length} available',
                style: FvmTuiTextStyles.muted,
              ),
            ],
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

final class ReleaseDetail extends StatelessWidget {
  const ReleaseDetail({required this.release, super.key});

  final TuiReleaseItem release;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 1,
    children: [
      Text(release.version, style: FvmTuiTextStyles.heading),
      StatusMarker(
        label: release.installed ? 'Installed' : 'Available',
        tone: release.installed ? TuiTone.success : TuiTone.info,
      ),
      DetailRow(label: 'Channel', value: release.channel),
      DetailRow(
        label: 'Released',
        value: release.releaseDate.toIso8601String().split('T').first,
      ),
      DetailRow(label: 'Dart SDK', value: release.dartSdkVersion ?? 'Unknown'),
      DetailRow(
        label: 'Architecture',
        value: release.architecture ?? 'Platform default',
      ),
      if (release.activeChannel)
        const StatusMarker(
          label: 'Current channel release',
          tone: TuiTone.info,
        ),
      if (!release.installed)
        const KeyHint(keyLabel: 'I', description: 'install'),
      const KeyHint(keyLabel: 'Escape', description: 'back to list'),
    ],
  );
}

String _description(TuiReleaseItem release) {
  final tags = [
    release.channel,
    if (release.activeChannel) 'current',
    if (release.installed) 'installed',
  ];

  return tags.join(' · ');
}

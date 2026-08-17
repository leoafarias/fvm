import 'package:noir/noir.dart';

import '../fvm_tui_controller.dart';
import '../fvm_tui_models.dart';
import '../theme/fvm_tui_theme.dart';
import '../widgets/terminal_primitives.dart';

final class VersionsScreen extends StatefulWidget {
  const VersionsScreen({
    required this.controller,
    required this.layoutMode,
    this.onUse,
    this.onInstall,
    super.key,
  });

  final FvmTuiController controller;
  final FvmTuiLayoutMode layoutMode;
  final VoidCallback? onUse;
  final VoidCallback? onInstall;

  @override
  State<VersionsScreen> createState() => _VersionsScreenState();
}

final class _VersionsScreenState extends State<VersionsScreen> {
  var _controllerRevision = 0;
  var _detailOpen = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    if (mounted) setState(() => _controllerRevision += 1);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!event.isPress || !_detailOpen) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.keyU) {
      widget.onUse?.call();

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyI) {
      widget.onInstall?.call();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _buildList(TuiVersionsData data) => Select(
    options: data.items
        .map(
          (item) => SelectOption(
            name: item.version,
            description: _description(item),
            value: item,
          ),
        )
        .toList(growable: false),
    selectedIndex: widget.controller.selectedVersionIndex,
    height: 14,
    showScrollIndicator: true,
    color: FvmTuiColors.primary,
    backgroundColor: FvmTuiColors.surface,
    selectedBackgroundColor: FvmTuiColors.selected,
    selectedTextColor: FvmTuiColors.primary,
    descriptionColor: FvmTuiColors.muted,
    autofocus: true,
    onChanged: (index, option) => widget.controller.selectVersion(index),
    onSelect: (index, option) {
      widget.controller.selectVersion(index);
      setState(() => _detailOpen = true);
    },
  );

  Widget _buildDetail(TuiVersionsData data) {
    if (!_detailOpen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 1,
        children: [
          Text('Version details', style: FvmTuiTextStyles.heading),
          Text(
            'Highlight with arrows and press Enter to inspect actions.',
            style: FvmTuiTextStyles.muted,
          ),
          DetailRow(label: 'Cache', value: data.cachePath),
          DetailRow(label: 'Size', value: '${data.cacheBytes} bytes'),
        ],
      );
    }
    final item = data.items[widget.controller.selectedVersionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 1,
      children: [
        Text(item.version, style: FvmTuiTextStyles.heading),
        DetailRow(label: 'Identity', value: item.id),
        DetailRow(label: 'Channel', value: item.channel),
        DetailRow(label: 'Metadata', value: item.metadata),
        StatusMarker(
          label: item.needsSetup ? 'Setup required' : 'Ready',
          tone: item.needsSetup ? TuiTone.warning : TuiTone.success,
        ),
        const KeyHint(keyLabel: 'U', description: 'use version'),
        const KeyHint(keyLabel: 'I', description: 'install/setup'),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant VersionsScreen oldWidget) {
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
      return Text('Loading installed SDKs…', style: FvmTuiTextStyles.muted);
    }
    final error = widget.controller.error;
    if (error != null) {
      return Text(
        'Could not load installed SDKs: $error',
        style: FvmTuiTextStyles.forTone(TuiTone.error),
      );
    }
    final data = widget.controller.versions;
    if (data == null || data.items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 1,
        children: [
          Text('No managed SDKs', style: FvmTuiTextStyles.heading),
          Text(
            'Open Releases to choose a Flutter SDK to install.',
            style: FvmTuiTextStyles.muted,
          ),
        ],
      );
    }
    final update = data.updateMessage;
    final body = widget.layoutMode == FvmTuiLayoutMode.wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 2,
            children: [
              SizedBox(width: 38, child: _buildList(data)),
              Expanded(child: _buildDetail(data)),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 1,
            children: [
              SizedBox(height: 10, child: _buildList(data)),
              Expanded(child: _buildDetail(data)),
            ],
          );

    return Focus(
      onKeyEvent: _handleKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 1,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Installed SDKs', style: FvmTuiTextStyles.heading),
              Text(
                '${data.items.length} cached',
                style: FvmTuiTextStyles.muted,
              ),
            ],
          ),
          if (update != null) StatusMarker(label: update, tone: TuiTone.info),
          Expanded(child: body),
        ],
      ),
    );
  }
}

String _description(TuiVersionItem item) {
  final tags = [
    item.channel,
    if (item.isGlobal) 'global',
    if (item.isProject) 'project',
    if (item.needsSetup) 'setup required',
  ];

  return tags.join(' · ');
}

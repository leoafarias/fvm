// ignore_for_file: prefer-single-widget-per-file

import 'package:noir/noir.dart';

import '../fvm_tui_models.dart';
import '../theme/fvm_tui_theme.dart';

final class NavigationItem extends StatelessWidget {
  const NavigationItem({
    required this.label,
    required this.shortcut,
    required this.selected,
    super.key,
  });

  final String label;
  final String shortcut;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    color: selected ? FvmTuiColors.selected : FvmTuiColors.panel,
    padding: const EdgeInsets.symmetric(horizontal: 1),
    child: Text(
      '$shortcut  $label',
      style: selected ? FvmTuiTextStyles.accent : FvmTuiTextStyles.muted,
      maxLines: 1,
    ),
  );
}

final class StatusMarker extends StatelessWidget {
  const StatusMarker({required this.label, required this.tone, super.key});

  final String label;
  final TuiTone tone;

  @override
  Widget build(BuildContext context) =>
      Text('● $label', style: FvmTuiTextStyles.forTone(tone), maxLines: 1);
}

final class KeyHint extends StatelessWidget {
  const KeyHint({required this.keyLabel, required this.description, super.key});

  final String keyLabel;
  final String description;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: '[$keyLabel] ', style: FvmTuiTextStyles.accent),
        TextSpan(text: description, style: FvmTuiTextStyles.muted),
      ],
    ),
    maxLines: 1,
  );
}

final class ToggleRow extends StatelessWidget {
  const ToggleRow({
    required this.label,
    required this.value,
    this.focused = false,
    super.key,
  });

  final String label;
  final bool value;
  final bool focused;

  @override
  Widget build(BuildContext context) => Container(
    color: focused ? FvmTuiColors.selected : FvmTuiColors.surface,
    padding: const EdgeInsets.symmetric(horizontal: 1),
    child: Text(
      '[${value ? 'x' : ' '}] $label',
      style: focused ? FvmTuiTextStyles.accent : FvmTuiTextStyles.body,
      maxLines: 1,
    ),
  );
}

final class DetailRow extends StatelessWidget {
  const DetailRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 18,
        child: Text(label, style: FvmTuiTextStyles.muted, maxLines: 1),
      ),
      Expanded(child: Text(value, style: FvmTuiTextStyles.body)),
    ],
  );
}

final class ProgressStep extends StatelessWidget {
  const ProgressStep({
    required this.label,
    required this.status,
    required this.detail,
    this.exactPercent,
    super.key,
  });

  final String label;
  final OperationStatus status;
  final String detail;
  final int? exactPercent;

  @override
  Widget build(BuildContext context) {
    final (symbol, tone) = switch (status) {
      OperationStatus.pending => ('○', TuiTone.neutral),
      OperationStatus.active => ('◆', TuiTone.info),
      OperationStatus.complete => ('●', TuiTone.success),
      OperationStatus.failed => ('×', TuiTone.error),
      OperationStatus.cancelled => ('–', TuiTone.warning),
    };
    final percent = exactPercent == null ? '' : ' $exactPercent%';

    return Text(
      '$symbol $label$percent  $detail',
      style: FvmTuiTextStyles.forTone(tone),
      maxLines: 1,
    );
  }
}

import 'package:noir/noir.dart';

import '../fvm_tui_models.dart';
import '../theme/fvm_tui_theme.dart';
import '../widgets/terminal_primitives.dart';

final class DoctorScreen extends StatefulWidget {
  const DoctorScreen({
    required this.report,
    required this.layoutMode,
    super.key,
  });

  final TuiDoctorReport report;
  final FvmTuiLayoutMode layoutMode;

  @override
  State<DoctorScreen> createState() => DoctorScreenState();
}

final class DoctorScreenState extends State<DoctorScreen> {
  var _selectedRecommendationIndex = 0;
  int? _expandedRecommendationIndex;

  int? get expandedRecommendationIndex => _expandedRecommendationIndex;

  void selectRecommendation(int index) {
    if (!mounted || widget.report.recommendations.isEmpty) return;
    setState(() {
      _selectedRecommendationIndex = index.clamp(
        0,
        widget.report.recommendations.length - 1,
      );
    });
  }

  void expandSelected() {
    if (!mounted || widget.report.recommendations.isEmpty) return;
    setState(() => _expandedRecommendationIndex = _selectedRecommendationIndex);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!event.isPress || widget.report.recommendations.isEmpty) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      selectRecommendation(_selectedRecommendationIndex - 1);

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      selectRecommendation(_selectedRecommendationIndex + 1);

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      expandSelected();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _section(DoctorSection section) => Container(
    decoration: BoxDecoration(
      color: FvmTuiColors.surface,
      border: Border.all(color: FvmTuiColors.border),
    ),
    padding: const EdgeInsets.all(1),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusMarker(label: section.name, tone: section.tone),
        ...section.checks.map(
          (check) => Text(
            '${_symbol(check.tone)} ${check.label}: ${check.value}',
            style: FvmTuiTextStyles.forTone(check.tone),
          ),
        ),
      ],
    ),
  );

  String _symbol(TuiTone tone) => switch (tone) {
    TuiTone.neutral => '○',
    TuiTone.info => '•',
    TuiTone.success => '✓',
    TuiTone.warning => '!',
    TuiTone.error => '×',
  };

  Widget _recommendations() {
    final recommendations = widget.report.recommendations;
    if (recommendations.isEmpty) {
      return Text(
        'No recommendations',
        style: FvmTuiTextStyles.forTone(TuiTone.success),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Recommendations', style: FvmTuiTextStyles.heading),
        for (var index = 0; index < recommendations.length; index++) ...[
          Container(
            color: index == _selectedRecommendationIndex
                ? FvmTuiColors.selected
                : FvmTuiColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(
              '${index == _selectedRecommendationIndex ? '›' : ' '} ${recommendations[index]}',
              style: index == _selectedRecommendationIndex
                  ? FvmTuiTextStyles.accent
                  : FvmTuiTextStyles.body,
            ),
          ),
          if (_expandedRecommendationIndex == index)
            Text('  ${recommendations[index]}', style: FvmTuiTextStyles.muted),
        ],
        const KeyHint(keyLabel: 'Enter', description: 'expand recommendation'),
      ],
    );
  }

  Widget _column(Iterable<DoctorSection> sections) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 1,
    children: sections.map(_section).toList(),
  );

  Widget _wide() {
    final sections = widget.report.sections;
    final left = <DoctorSection>[];
    final right = <DoctorSection>[];
    for (var index = 0; index < sections.length; index++) {
      (index.isEven ? left : right).add(sections[index]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 1,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 1,
            children: [
              Expanded(child: _column(left)),
              Expanded(child: _column(right)),
            ],
          ),
        ),
        _recommendations(),
      ],
    );
  }

  Widget _compact() => ScrollBox(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 1,
      children: [...widget.report.sections.map(_section), _recommendations()],
    ),
  );

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: _handleKey,
    child: widget.layoutMode == FvmTuiLayoutMode.wide ? _wide() : _compact(),
  );
}

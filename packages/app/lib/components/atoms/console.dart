import 'package:fvm_app/components/atoms/cache_size_display.dart';
import 'package:fvm_app/components/atoms/typography.dart';
import 'package:fvm_app/providers/installed_versions.provider.dart';
import 'package:fvm_app/providers/fvm_console_provider.dart';
import 'package:fvm_app/providers/projects_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class Console extends HookWidget {
  final List<ConsoleLine> lines;
  final bool expand;
  final bool processing;
  final Function() onExpand;
  const Console({
    this.lines,
    this.expand = false,
    this.processing = false,
    this.onExpand,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final output = useProvider(combinedConsoleProvider);
    final lines = useState<List<String>>(['']);
    final installedList = useProvider(installedVersionsProvider);
    final projects = useProvider(projectsProvider.state);

    useValueChanged(output, (_, __) {
      lines.value.insert(0, output.data.value);
      if (lines.value.length > 100) {
        lines.value.removeAt(lines.value.length - 1);
      }
    });

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState:
          processing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: Container(
        color: Colors.black45,
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 20),
            installedList.isNotEmpty
                ? TypographyCaption('${installedList.length} Versions')
                : const TypographyCaption('Versions'),
            const SizedBox(width: 20),
            const CacheSizeDisplay(),
            const SizedBox(width: 20),
            projects.loading
                ? const TypographyCaption('Loading Projects...')
                : TypographyCaption('${projects.list.length} Projects'),
            const SizedBox(width: 20),
          ],
        ),
      ),
      secondChild: GestureDetector(
        onTap: onExpand,
        child: Container(
          color: Colors.black45,
          height: expand ? 160 : 40,
          constraints: expand
              ? const BoxConstraints(maxHeight: 160)
              : const BoxConstraints(maxHeight: 40),
          child: Stack(
            children: [
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: expand
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextStdout(lines.value.first),
                    ],
                  ),
                ),
                secondChild: Scrollbar(
                  child: ListView.builder(
                    shrinkWrap: true,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    itemBuilder: (context, index) {
                      final line = lines.value[index];
                      if (line == OutputType.stdout) {
                        return TextStdout(
                          lines.value[index],
                          key: Key(lines.value[index]),
                        );
                      } else {
                        return TextStdout(
                          lines.value[index],
                          key: Key(lines.value[index]),
                        );
                      }
                    },
                    itemCount: lines.value.length,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  children: [
                    const SpinKitFadingFour(color: Colors.cyan, size: 15),
                    IconButton(
                      onPressed: null,
                      icon: expand
                          ? const Icon(MdiIcons.chevronDown)
                          : const Icon(MdiIcons.chevronUp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

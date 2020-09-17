import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FvmGroupListTile extends HookWidget {
  final Widget title;
  final Widget leading;
  final Widget trailing;
  final bool border;
  final List<Widget> children;

  const FvmGroupListTile({
    Key key,
    this.title,
    this.leading,
    this.trailing,
    this.border = false,
    this.children = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(false);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: isExpanded.value
          ? const EdgeInsets.fromLTRB(0, 10, 0, 10)
          : const EdgeInsets.all(0),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            width: border ? 1 : 0,
            color: Colors.white10,
          ),
        ),
      ),
      child: ExpansionTile(
        title: title,
        leading: leading,
        trailing: trailing,
        children: children,
        tilePadding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
        backgroundColor: Colors.white12,
        onExpansionChanged: (expanded) {
          isExpanded.value = expanded;
        },
      ),
    );
  }
}

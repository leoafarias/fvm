import 'package:fvm_app/components/atoms/typography.dart';
import 'package:flutter/material.dart';

class FvmAppBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const FvmAppBar({this.title, this.actions, key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TypographyTitle(title),
      centerTitle: false,
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(
          height: 0,
          thickness: 0.5,
        ),
      ),
      automaticallyImplyLeading: false,
      // shadowColor: Colors.transparent,
      // backgroundColor: Colors.transparent,
      // flexibleSpace: const BlurBackground(),
    );
  }
}

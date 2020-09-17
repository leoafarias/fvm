import 'package:fvm_app/components/atoms/blur_background.dart';
import 'package:fvm_app/components/atoms/typography.dart';
import 'package:flutter/material.dart';

class FvmAppBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const FvmAppBar({this.title, this.actions, key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: FvmTitle(title),
      backgroundColor: Colors.transparent,
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
      flexibleSpace: const BlurBackground(),
    );
  }
}

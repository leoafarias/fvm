import 'package:fvm_app/components/atoms/app_bar.dart';
import 'package:flutter/material.dart';

class FvmScreen extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget child;
  const FvmScreen({this.title, this.actions, this.child, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: FvmAppBar(
          title: title,
          actions: actions ?? [const SizedBox(height: 0, width: 0)],
        ),
      ),
      body: child,
    );
  }
}

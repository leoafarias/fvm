// https://medium.com/@eibaan_54644/reappearing-app-bar-titles-eff8b35f6826

import 'package:flutter/material.dart';

class SliverAppBarSwitcher extends StatefulWidget {
  final Widget child;

  const SliverAppBarSwitcher({
    Key key,
    @required this.child,
  }) : super(key: key);
  @override
  _SliverAppBarSwitcherState createState() {
    return _SliverAppBarSwitcherState();
  }
}

class _SliverAppBarSwitcherState extends State<SliverAppBarSwitcher> {
  ScrollPosition _position;
  bool _visible;
  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _removeListener();
    _addListener();
  }

  void _addListener() {
    _position = Scrollable.of(context)?.position;
    _position?.addListener(_positionListener);
    _positionListener();
  }

  void _removeListener() {
    _position?.removeListener(_positionListener);
  }

  void _positionListener() {
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();

    final visible =
        settings == null || settings.currentExtent < settings.minExtent + 10;
    if (_visible != visible) {
      setState(() {
        _visible = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: _visible ? widget.child : Container(),
    );
  }
}

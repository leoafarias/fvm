import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SliverSection extends StatelessWidget {
  final List<Widget> slivers;
  final bool shouldDisplay;

  const SliverSection({
    Key key,
    this.slivers,
    this.shouldDisplay = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!shouldDisplay) {
      return SliverToBoxAdapter(
        child: Container(),
      );
    }
    return SliverToBoxAdapter(
      child: ShrinkWrappingViewport(
        offset: ViewportOffset.zero(),
        slivers: slivers,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final int count;
  final Function onPress;
  final double height;

  SectionHeaderDelegate({
    this.title,
    this.count = 0,
    this.onPress,
    this.height = 50,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.black38,
      child: ListTile(
        title: Text(title),
        trailing: Text('${count.toString()} Found'),
        onTap: onPress,
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}

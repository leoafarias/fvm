import 'package:flutter/material.dart';
import 'package:fvm_app/components/atoms/typography.dart';
import 'package:pub_api_client/pub_api_client.dart';

class PackageScoreDisplay extends StatelessWidget {
  final PackageScore score;
  const PackageScoreDisplay({
    this.score,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypographyTitle(score.likeCount.toString()),
              const TypographyCaption('Likes'),
            ],
          ),
          const VerticalDivider(width: 25),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypographyTitle(score.grantedPoints.toString()),
              const TypographyCaption('Pub Points'),
            ],
          ),
          const VerticalDivider(width: 25),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypographyTitle(
                  '${(score.popularityScore * 100).toStringAsFixed(0)}%'),
              const TypographyCaption('Popularity'),
            ],
          ),
        ],
      ),
    );
  }
}

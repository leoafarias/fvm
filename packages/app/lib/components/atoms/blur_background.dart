import 'dart:ui';

import 'package:flutter/material.dart';

class BlurBackground extends StatelessWidget {
  final double strength;
  const BlurBackground({Key key, this.strength = 10.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: strength, sigmaY: strength),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

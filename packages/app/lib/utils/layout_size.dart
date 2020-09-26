import 'package:flutter/material.dart';

enum LayoutSizeOption {
  small,
  medium,
  large,
}

class LayoutSize {
  static LayoutSizeOption size = LayoutSizeOption.small;
  LayoutSize();

  static void init(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    size = LayoutSizeOption.small;
    if (width > 860) {
      size = LayoutSizeOption.medium;
    }
    if (width > 1024) {
      size = LayoutSizeOption.large;
    }
  }

  static bool get isSmall {
    return size == LayoutSizeOption.small;
  }

  static bool get isMedium {
    return size == LayoutSizeOption.medium;
  }

  static bool get isLarge {
    return size == LayoutSizeOption.large;
  }
}

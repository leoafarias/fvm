import 'package:flutter/material.dart';

const kIconSize = 100.0;

const kIconsPosition = [
  // Center
  {
    'size': 1,
    'top': 0.0,
    'left': 0.0,
    'right': 0.0,
    'bottom': 0.0,
    'opacity': 0.2
  },
  // Top Section
  {'size': 0.30, 'top': 0.0, 'left': 0.0, 'opacity': 0.25},
  {'size': 0.50, 'top': 50.0, 'left': 30.0, 'opacity': 0.1},
  {'size': 0.50, 'top': 0.0, 'right': 0.0, 'opacity': 0.30},
  {'size': 0.40, 'top': 80.0, 'right': 0.0, 'opacity': 0.20},
  {'size': 0.50, 'top': 0.0, 'right': 1.0, 'opacity': 0.25},
  {'size': 0.40, 'top': 30.0, 'right': 90.0, 'opacity': 0.15},
  {'size': 0.3, 'top': 40.0, 'left': 150.0, 'opacity': 0.3},
  {'size': 0.20, 'top': 0.0, 'left': 130.0, 'opacity': 0.2},

  //Bottom section
  {'size': 0.40, 'bottom': 150.0, 'left': 60.0, 'opacity': 0.20},
  {'size': 0.50, 'bottom': 90.0, 'right': 30.0, 'opacity': 0.1},
  {'size': 0.30, 'bottom': 80.0, 'left': 30.0, 'opacity': 0.30},
  {'size': 0.6, 'bottom': 50.0, 'right': 100.0, 'opacity': 0.2},
  {'size': 0.40, 'bottom': 50.0, 'left': 90.0, 'opacity': 0.15},
  {'size': 0.30, 'bottom': 10.0, 'right': 0.0, 'opacity': 0.25},
  {'size': 0.50, 'bottom': 0.0, 'left': 1.0, 'opacity': 0.25},
  {'size': 0.3, 'bottom': 0.0, 'left': 130.0, 'opacity': 0.2},
];

class EmptyDataSet extends StatelessWidget {
  final Widget icon;
  final Color iconColor;
  final Color backgroundColor;
  final Widget child;

  const EmptyDataSet({
    this.icon,
    this.iconColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bgIcons = _buildIconsBackground(icon: icon, color: iconColor);

    return Stack(
      children: [
        Opacity(
          opacity: 0.3,
          child: Center(
            child: ClipRRect(
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: 350,
                height: 350,
                margin: const EdgeInsets.all(0.0),
                child: Stack(
                  children: bgIcons,
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 450,
            height: 350,
            child: child,
          ),
        ),
      ],
    );
  }
}

List<Widget> _buildIconsBackground({Widget icon, Color color}) {
  if (icon is Icon) {
    return kIconsPosition.map((i) {
      return Positioned(
        top: i['top'],
        bottom: i['bottom'],
        left: i['left'],
        right: i['right'],
        child: Icon(
          icon.icon,
          size: kIconSize * i['size'],
          color: color?.withOpacity(i['opacity']),
        ),
      );
    }).toList();
  }
  return kIconsPosition.map((i) {
    return Positioned(
      top: i['top'],
      bottom: i['bottom'],
      left: i['left'],
      right: i['right'],
      child: Opacity(
        opacity: i['opacity'],
        child: SizedBox(
          height: kIconSize * i['size'],
          width: kIconSize * i['size'],
          child: icon,
        ),
      ),
    );
  }).toList();
}

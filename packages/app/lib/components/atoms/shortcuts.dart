import 'package:fvm_app/providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavigationIntent extends Intent {
  final NavigationRoutes route;
  const NavigationIntent({this.route});
}

class KBShortcutManager extends StatefulWidget {
  final Widget child;

  final Function(NavigationRoutes) onRouteShortcut;
  final FocusNode focusNode;
  // final KBShortcuts shortcuts;

  const KBShortcutManager({
    Key key,
    this.onRouteShortcut,
    this.child,
    this.focusNode,
  }) : super(key: key);

  @override
  _KBShortcutManagerState createState() => _KBShortcutManagerState();
}

class _KBShortcutManagerState extends State<KBShortcutManager> {
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.digit1,
        ): const NavigationIntent(route: NavigationRoutes.homeScreen),
        LogicalKeySet(
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.digit2,
        ): const NavigationIntent(route: NavigationRoutes.projectsScreen),
        LogicalKeySet(
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.digit3,
        ): const NavigationIntent(route: NavigationRoutes.exploreScreen),
        LogicalKeySet(
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.digit4,
        ): const NavigationIntent(route: NavigationRoutes.packagesScreen),
        LogicalKeySet(
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.digit5,
        ): const NavigationIntent(route: NavigationRoutes.settingsScreen),
        LogicalKeySet(
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.keyF,
        ): const NavigationIntent(route: NavigationRoutes.searchScreen),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          NavigationIntent: CallbackAction<NavigationIntent>(
              onInvoke: (intent) => widget.onRouteShortcut(intent.route)),
        },
        child: Focus(
          autofocus: true,
          focusNode: widget.focusNode,
          child: widget.child,
        ),
      ),
    );
  }
}

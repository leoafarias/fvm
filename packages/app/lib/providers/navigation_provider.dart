import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

enum NavigationRoutes {
  homeScreen,
  projectsScreen,
  exploreScreen,
  packagesScreen,
  settingsScreen,
  searchScreen,
}

final navigationProvider = StateNotifierProvider<NavigationProvider>((_) {
  return NavigationProvider();
});

class NavigationProvider extends StateNotifier<NavigationRoutes> {
  NavigationRoutes previous;
  NavigationProvider({NavigationRoutes route = NavigationRoutes.homeScreen})
      : previous = route,
        super(route);

  void goTo(NavigationRoutes navigation) {
    // Sets prev index for goBack method
    previous = state;
    state = navigation;
  }

  void goBack() {
    goTo(previous);
  }
}

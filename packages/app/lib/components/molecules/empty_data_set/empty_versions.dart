import 'package:fvm_app/components/atoms/empty_data_set.dart';
import 'package:fvm_app/providers/navigation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class EmptyVersions extends StatelessWidget {
  const EmptyVersions({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyDataSet(
      icon: const FlutterLogo(),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Flutter SDK not installed.',
              style: Theme.of(context).textTheme.headline5,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '''You do not currently have any Flutter version installed.Versions or channels that have been installed will be displayed here.''',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.caption,
            ),
            const SizedBox(height: 20),
            RaisedButton.icon(
              padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
              onPressed: () {
                context
                    .read(navigationProvider)
                    .goTo(NavigationRoutes.exploreScreen);
              },
              icon: const Icon(Icons.explore),
              label: const Text('View Flutter SDK Versions'),
            )
          ],
        ),
      ),
    );
  }
}

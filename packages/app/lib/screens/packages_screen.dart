import 'package:fvm_app/components/atoms/list_tile.dart';
import 'package:fvm_app/components/atoms/loading_indicator.dart';
import 'package:fvm_app/components/atoms/screen.dart';
import 'package:fvm_app/components/atoms/typography.dart';
import 'package:fvm_app/components/molecules/github_info_display.dart';
import 'package:fvm_app/components/molecules/package_score_display.dart';

import 'package:fvm_app/providers/project_dependencies.provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fvm_app/utils/github_parse.dart';

import 'package:fvm_app/utils/open_link.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PackagesScreen extends HookWidget {
  const PackagesScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final packages = useProvider(projectDependenciesProvider);

    return packages.when(
        data: (data) {
          return FvmScreen(
            title: 'Your Most Popular Packages',
            child: Scrollbar(
              child: ListView.builder(
                // separatorBuilder: (_, __) => const Divider(),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final pkg = data[index];
                  final position = ++index;
                  return Container(
                    height: 150,
                    child: Column(
                      children: [
                        FvmListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.black26,
                            child: Text(position.toString()),
                          ),
                          title: Text(pkg.package.name),
                          subtitle: Text(
                            pkg.package.description,
                            maxLines: 2,
                            style: Theme.of(context).textTheme.caption,
                          ),
                          trailing: PackageScoreDisplay(score: pkg.score),
                        ),
                        const Divider(thickness: 0.5),
                        Row(
                          children: [
                            GithubInfoDisplay(
                              key: Key(pkg.package.name),
                              repoSlug: getRepoSlugFromPubspec(
                                  pkg.package.latestPubspec),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TypographyCaption(pkg.package.version),
                                      const SizedBox(width: 10),
                                      const Text('·'),
                                      const SizedBox(width: 10),
                                      TextButton(
                                        child: const Text('details'),
                                        onPressed: () async {
                                          await openLink(pkg.package.url);
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      const Text('·'),
                                      const SizedBox(width: 10),
                                      TextButton(
                                        child: const Text('changelog'),
                                        onPressed: () async {
                                          await openLink(
                                              pkg.package.changelogUrl);
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      const Text('·'),
                                      const SizedBox(width: 10),
                                      TextButton(
                                        child: const Text('website'),
                                        onPressed: () async {
                                          await openLink(pkg
                                              .package.latestPubspec.homepage);
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const Divider()
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (_, __) => Container());
  }
}

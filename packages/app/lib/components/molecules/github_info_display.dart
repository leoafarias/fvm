import 'package:fvm_app/providers/project_dependencies.provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:github/github.dart';
import 'package:hooks_riverpod/all.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class GithubInfoDisplay extends HookWidget {
  final RepositorySlug repoSlug;
  const GithubInfoDisplay({
    this.repoSlug,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repo = useProvider(getGithubRepositoryProvider(repoSlug));

    return repo.when(data: (data) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlatButton.icon(
            icon: Icon(Icons.star, size: 15),
            label: Text(data.stargazersCount.toString()),
          ),
          const SizedBox(width: 10),
          FlatButton.icon(
            icon: Icon(MdiIcons.alertCircleOutline, size: 15),
            label: Text(data.openIssuesCount.toString()),
          ),
          const SizedBox(width: 10),
          FlatButton.icon(
            icon: Icon(MdiIcons.sourceFork, size: 15),
            label: Text(data.forksCount.toString()),
          ),
        ],
      );
    }, loading: () {
      return Expanded(child: LinearProgressIndicator());
    }, error: (_, __) {
      return Container();
    });
  }
}

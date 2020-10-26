import 'package:fvm_app/utils/http_cache.dart';
import 'package:http/http.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:github/github.dart';

class GithubInfoDisplay extends HookWidget {
  final RepositorySlug repoSlug;
  const GithubInfoDisplay({
    this.repoSlug,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repo = useState<Repository>();

    Future<void> loadGitHubInfo() async {
      final github = GitHub(
        auth: Authentication.withToken(
            'fa01cbd4098cb70784d31b8383e32f7f68ee9526'),
        client: CacheHttpClient(),
      );

      repo.value = await github.repositories.getRepository(repoSlug);
    }

    useEffect(() {
      if (repoSlug == null) return;
      loadGitHubInfo();
    }, []);

    if (repo.value == null) {
      return const LinearProgressIndicator();
    }

    return Expanded(
      child: Row(
        children: [
          Text(repo.value.stargazersCount.toString()),
          const SizedBox(width: 10),
          Text(repo.value.watchersCount.toString()),
          const SizedBox(width: 10),
          Text(repo.value.openIssuesCount.toString()),
        ],
      ),
    );
  }
}

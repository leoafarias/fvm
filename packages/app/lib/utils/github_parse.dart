import 'package:github/github.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

RepositorySlug getRepoSlugFromPubspec(Pubspec pubspec) {
  String author;
  String repo;

  if (pubspec.repository != null) {
    final paths = pubspec.repository.path.split('/');
    author = paths[1];
    repo = paths[2];
  } else {
    if (pubspec.homepage != null && pubspec.homepage.contains('github.com')) {
      final uri = Uri.parse(pubspec.homepage);
      final paths = uri.path.split('/');
      author = paths[1];
      repo = paths[2];
    }
  }
  if (author != null && repo != null) {
    return RepositorySlug(author, repo);
  } else {
    return null;
  }
}

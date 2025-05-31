import 'dart:convert';

import 'package:dart_mappable/dart_mappable.dart';

part 'git_reference_model.mapper.dart';

// Renamed to GitReference to be more descriptive
@MappableClass()
abstract class GitReference with GitReferenceMappable {
  final String sha;
  final String name;

  const GitReference({required this.sha, required this.name});

  static List<GitReference> parseGitReferences(String output) {
    return _parseGitReferences(output);
  }
}

const _localBranchPrefix = 'refs/heads/';
const _localTagPrefix = 'refs/tags/';

// Renamed function to better describe what it does
List<GitReference> _parseGitReferences(String input) {
  final lines = const LineSplitter().convert(input);
  final references = <GitReference>[];

  for (final line in lines) {
    final reference = _parseFromLine(line);
    if (reference != null) {
      references.add(reference);
    }
  }

  return references;
}

GitReference? _parseFromLine(String line) {
  final parts = line.split('\t');
  if (parts.length != 2) return null;

  final sha = parts[0];
  final ref = parts[1];

  if (ref.startsWith(_localBranchPrefix)) {
    return GitBranch(sha: sha, name: ref.substring(_localBranchPrefix.length));
  }

  if (ref.startsWith(_localTagPrefix) && !ref.endsWith('^{}')) {
    return GitTag(sha: sha, name: ref.substring(_localTagPrefix.length));
  }

  return null;
}

@MappableClass()
class GitBranch extends GitReference with GitBranchMappable {
  const GitBranch({required super.sha, required super.name});
}

@MappableClass()
class GitTag extends GitReference with GitTagMappable {
  const GitTag({required super.sha, required super.name});
}

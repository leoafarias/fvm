import 'package:fvm/src/models/git_reference_model.dart';
import 'package:test/test.dart';

// A simplified version of the structure in flutter_git_references.json
final Map<String, dynamic> mockReferenceData = {
  'channels': {
    'stable': {
      'name': 'stable',
      'hash': 'ea121f8859e4b13e47a8f845e4586164519588bc',
      'type': 'branch'
    },
    'beta': {
      'name': 'beta',
      'hash': '3bd718ee44049e25d33327ee9886ec30c97ffa33',
      'type': 'branch'
    },
    'dev': {
      'name': 'dev',
      'hash': 'd6260f127fe3f88c98231243b387b48448479bff',
      'type': 'branch'
    }
  },
  'releases': {
    '3.0.0': {
      'name': '3.0.0',
      'hash': 'ee4e09cce01d6f2d7f4baebd247fde02e5008851',
      'type': 'tag'
    },
    '2.10.5': {
      'name': '2.10.5',
      'hash': '5464c5bac742001448fe4fc0597be939379f88ea',
      'type': 'tag'
    }
  },
  'gitReferences': [
    {
      'name': 'refs/heads/stable',
      'hash': 'ea121f8859e4b13e47a8f845e4586164519588bc',
      'type': 'branch'
    },
    {
      'name': 'refs/heads/beta',
      'hash': '3bd718ee44049e25d33327ee9886ec30c97ffa33',
      'type': 'branch'
    },
    {
      'name': 'refs/heads/dev',
      'hash': 'd6260f127fe3f88c98231243b387b48448479bff',
      'type': 'branch'
    },
    {
      'name': 'refs/tags/3.0.0',
      'hash': 'ee4e09cce01d6f2d7f4baebd247fde02e5008851',
      'type': 'tag'
    },
    {
      'name': 'refs/tags/2.10.5',
      'hash': '5464c5bac742001448fe4fc0597be939379f88ea',
      'type': 'tag'
    }
  ]
};

// Helper function to generate git ls-remote output format from our reference data
String generateLsRemoteOutput(List<dynamic> references) {
  final buffer = StringBuffer();
  for (final ref in references) {
    buffer.writeln('${ref['hash']}\t${ref['name']}');
  }
  return buffer.toString();
}

void main() {
  group('Git reference model', () {
    test('can parse git reference from ls-remote output', () {
      // Arrange
      final lsRemoteOutput =
          generateLsRemoteOutput(mockReferenceData['gitReferences']);

      // Act
      final references = GitReference.parseGitReferences(lsRemoteOutput);

      // Assert
      expect(references, isNotEmpty);

      // Verify branch references
      final branches = references.whereType<GitBranch>();
      expect(branches, isNotEmpty);

      final stableBranch = branches.firstWhere(
        (ref) => ref.name == 'stable',
        orElse: () => const GitBranch(name: '', sha: ''),
      );

      // Check branch properties
      expect(stableBranch.name, equals('stable'));
      expect(
          stableBranch.sha, equals('ea121f8859e4b13e47a8f845e4586164519588bc'));

      // Verify tag references
      final tags = references.whereType<GitTag>();
      expect(tags, isNotEmpty);

      final releaseTag = tags.firstWhere(
        (ref) => ref.name == '3.0.0',
        orElse: () => const GitTag(name: '', sha: ''),
      );

      // Check tag properties
      expect(releaseTag.name, equals('3.0.0'));
      expect(
          releaseTag.sha, equals('ee4e09cce01d6f2d7f4baebd247fde02e5008851'));
    });

    test('separates branches and tags correctly', () {
      // Arrange
      final lsRemoteOutput = '''
ea121f8859e4b13e47a8f845e4586164519588bc	refs/heads/stable
3bd718ee44049e25d33327ee9886ec30c97ffa33	refs/heads/beta
d6260f127fe3f88c98231243b387b48448479bff	refs/heads/dev
ee4e09cce01d6f2d7f4baebd247fde02e5008851	refs/tags/3.0.0
5464c5bac742001448fe4fc0597be939379f88ea	refs/tags/2.10.5
''';

      // Act
      final references = GitReference.parseGitReferences(lsRemoteOutput);

      // Assert
      final branches = references.whereType<GitBranch>();
      final tags = references.whereType<GitTag>();

      expect(branches.length, equals(3));
      expect(tags.length, equals(2));

      // Check branch names
      expect(branches.map((b) => b.name).toSet(),
          equals(<String>{'stable', 'beta', 'dev'}));

      // Check tag names
      expect(
          tags.map((t) => t.name).toSet(), equals(<String>{'3.0.0', '2.10.5'}));
    });

    test('ignores invalid reference lines', () {
      // Arrange
      final lsRemoteOutput = '''
ea121f8859e4b13e47a8f845e4586164519588bc	refs/heads/stable
invalid line without tab
3bd718ee44049e25d33327ee9886ec30c97ffa33	refs/heads/beta
random text	not a valid reference
ee4e09cce01d6f2d7f4baebd247fde02e5008851	refs/tags/3.0.0
''';

      // Act
      final references = GitReference.parseGitReferences(lsRemoteOutput);

      // Assert - should only get the valid lines
      expect(references.length, equals(3));

      final branches = references.whereType<GitBranch>();
      final tags = references.whereType<GitTag>();

      expect(branches.length, equals(2));
      expect(tags.length, equals(1));
    });
  });
}

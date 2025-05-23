import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/utils/helpers.dart';

/// Mock implementation of GitService for testing
class MockGitService extends GitService {
  final Map<String, String> _versionBranches = {};
  final Map<String, String> _versionTags = {};
  final Map<String, String> _versionCommits = {};

  MockGitService(super.context);

  /// Sets the branch for a specific version
  void setBranch(String version, String branch) {
    _versionBranches[version] = branch;
  }

  /// Sets the tag for a specific version
  void setTag(String version, String tag) {
    _versionTags[version] = tag;
  }

  /// Sets the commit hash for a specific version
  void setCommit(String version, String commit) {
    _versionCommits[version] = commit;
  }

  @override
  Future<String> getBranch(String version) async {
    // Check if we have a pre-set branch for this version
    if (_versionBranches.containsKey(version)) {
      return _versionBranches[version]!;
    }

    // For channels, return the channel name as the branch
    if (isFlutterChannel(version)) {
      return version;
    }
    
    // Check for version@channel syntax (e.g., 2.2.2@beta)
    if (version.contains('@')) {
      final parts = version.split('@');
      if (parts.length == 2) {
        return parts[1]; // Return the channel part
      }
    }
    
    // For commit hashes, return master as Flutter typically uses master for non-release commits
    if (RegExp(r'^[a-f0-9]{7,40}$').hasMatch(version)) {
      return 'master';
    }

    // For other versions, default to stable
    return 'stable';
  }

  @override
  Future<String?> getTag(String version) async {
    // Check if we have a pre-set tag for this version
    if (_versionTags.containsKey(version)) {
      return _versionTags[version]!;
    }

    // For semantic versions, return the version as the tag
    if (RegExp(r'^\d+\.\d+\.\d+').hasMatch(version)) {
      return version;
    }

    return null;
  }

  @override
  Future<String> getCommit(String version) async {
    // Check if we have a pre-set commit for this version
    if (_versionCommits.containsKey(version)) {
      return _versionCommits[version]!;
    }

    // For commit hashes, return the hash itself
    if (RegExp(r'^[a-f0-9]{7,40}$').hasMatch(version)) {
      return version;
    }

    // Default to a dummy commit hash
    return 'abcdef1234567890';
  }

  @override
  Future<bool> isValid(String version) async {
    // For testing, consider all versions valid
    return true;
  }
}
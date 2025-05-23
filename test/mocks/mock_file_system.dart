import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

/// A class to mock File operations for testing
class MockFile implements File {
  final String _path;
  Uint8List? _content;
  final Map<String, MockFile> _files;
  final Map<String, MockDirectory> _directories;
  final Map<String, String> _symlinks;
  final Map<String, Exception> _failureScenarios;
  bool _exists;

  MockFile(
    this._path,
    this._files,
    this._directories,
    this._symlinks,
    this._failureScenarios, {
    Uint8List? content,
    bool exists = false,
  })  : _content = content,
        _exists = exists;

  @override
  String get path => _path;

  @override
  bool existsSync() {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('existsSync:$_path')) {
      throw _failureScenarios['existsSync:$_path']!;
    }
    return _exists;
  }

  @override
  File writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('writeAsStringSync:$_path')) {
      throw _failureScenarios['writeAsStringSync:$_path']!;
    }

    // Create parent directories if needed
    final parent = Directory(p.dirname(_path));
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    // Write the content
    _content = Uint8List.fromList(encoding.encode(contents));
    _exists = true;
    _files[_path] = this;
    return this;
  }

  @override
  String readAsStringSync({Encoding encoding = utf8}) {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('readAsStringSync:$_path')) {
      throw _failureScenarios['readAsStringSync:$_path']!;
    }

    if (!_exists) {
      throw FileSystemException('File not found', _path);
    }

    return encoding.decode(_content!);
  }

  @override
  File writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('writeAsBytesSync:$_path')) {
      throw _failureScenarios['writeAsBytesSync:$_path']!;
    }

    // Create parent directories if needed
    final parent = Directory(p.dirname(_path));
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    // Write the content
    _content = Uint8List.fromList(bytes);
    _exists = true;
    _files[_path] = this;
    return this;
  }

  @override
  Uint8List readAsBytesSync() {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('readAsBytesSync:$_path')) {
      throw _failureScenarios['readAsBytesSync:$_path']!;
    }

    if (!_exists) {
      throw FileSystemException('File not found', _path);
    }

    return _content!;
  }

  @override
  File copySync(String newPath) {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('copySync:$_path')) {
      throw _failureScenarios['copySync:$_path']!;
    }

    if (!_exists) {
      throw FileSystemException('File not found', _path);
    }

    final newFile = MockFile(
      newPath,
      _files,
      _directories,
      _symlinks,
      _failureScenarios,
      content: _content,
      exists: true,
    );
    _files[newPath] = newFile;
    return newFile;
  }

  @override
  void deleteSync({bool recursive = false}) {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('deleteSync:$_path')) {
      throw _failureScenarios['deleteSync:$_path']!;
    }

    if (!_exists) {
      throw FileSystemException('File not found', _path);
    }

    _exists = false;
    _content = null;
    _files.remove(_path);
  }

  @override
  Directory get parent => Directory(p.dirname(_path));

  @override
  String resolveSymbolicLinksSync() {
    // Check if this file is a symlink
    if (_symlinks.containsKey(_path)) {
      return _symlinks[_path]!;
    }
    return _path;
  }

  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Method ${invocation.memberName} not implemented in MockFile',
    );
  }
}

/// A class to mock Directory operations for testing
class MockDirectory implements Directory {
  final String _path;
  final Map<String, MockFile> _files;
  final Map<String, MockDirectory> _directories;
  final Map<String, String> _symlinks;
  final Map<String, Exception> _failureScenarios;
  bool _exists;

  MockDirectory(
    this._path,
    this._files,
    this._directories,
    this._symlinks,
    this._failureScenarios, {
    bool exists = false,
  }) : _exists = exists;

  @override
  String get path => _path;

  @override
  bool existsSync() {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('existsSync:$_path')) {
      throw _failureScenarios['existsSync:$_path']!;
    }
    return _exists;
  }

  @override
  Directory createSync({bool recursive = false}) {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('createSync:$_path')) {
      throw _failureScenarios['createSync:$_path']!;
    }

    if (recursive) {
      // Create parent directories if needed
      var parent = p.dirname(_path);
      if (parent != _path && parent != '.' && parent != '/') {
        final parentDir = MockDirectory(
          parent,
          _files,
          _directories,
          _symlinks,
          _failureScenarios,
        );
        if (!_directories.containsKey(parent)) {
          parentDir.createSync(recursive: true);
        }
      }
    }

    _exists = true;
    _directories[_path] = this;
    return this;
  }

  @override
  void deleteSync({bool recursive = false}) {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('deleteSync:$_path')) {
      throw _failureScenarios['deleteSync:$_path']!;
    }

    if (!_exists) {
      throw FileSystemException('Directory not found', _path);
    }

    if (recursive) {
      // Delete all files and subdirectories
      final dirPrefix = _path.endsWith('/') ? _path : '$_path/';

      // Delete files
      _files.keys
          .where((filePath) => filePath.startsWith(dirPrefix))
          .toList()
          .forEach((filePath) {
        _files.remove(filePath);
      });

      // Delete directories
      _directories.keys
          .where((dirPath) => dirPath.startsWith(dirPrefix) && dirPath != _path)
          .toList()
          .forEach((dirPath) {
        _directories.remove(dirPath);
      });

      // Delete symlinks
      _symlinks.keys
          .where((linkPath) => linkPath.startsWith(dirPrefix))
          .toList()
          .forEach((linkPath) {
        _symlinks.remove(linkPath);
      });
    } else {
      // Check if directory is empty
      final dirPrefix = _path.endsWith('/') ? _path : '$_path/';
      final hasFiles =
          _files.keys.any((filePath) => filePath.startsWith(dirPrefix));
      final hasSubdirs = _directories.keys
          .any((dirPath) => dirPath.startsWith(dirPrefix) && dirPath != _path);
      final hasSymlinks =
          _symlinks.keys.any((linkPath) => linkPath.startsWith(dirPrefix));

      if (hasFiles || hasSubdirs || hasSymlinks) {
        throw FileSystemException('Directory not empty', _path);
      }
    }

    _exists = false;
    _directories.remove(_path);
  }

  @override
  Directory get parent => Directory(p.dirname(_path));

  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Method ${invocation.memberName} not implemented in MockDirectory',
    );
  }
}

/// A class to mock Link operations for testing
class MockLink implements Link {
  final String _path;
  final Map<String, String> _symlinks;
  final Map<String, Exception> _failureScenarios;
  bool _exists;
  String? _target;

  MockLink(
    this._path,
    this._symlinks,
    this._failureScenarios, {
    bool exists = false,
    String? target,
  })  : _exists = exists,
        _target = target;

  @override
  String get path => _path;

  @override
  bool existsSync() {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('existsSync:$_path')) {
      throw _failureScenarios['existsSync:$_path']!;
    }
    return _exists && _symlinks.containsKey(_path);
  }

  @override
  String targetSync() {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('targetSync:$_path')) {
      throw _failureScenarios['targetSync:$_path']!;
    }

    if (!_exists || !_symlinks.containsKey(_path)) {
      throw FileSystemException('Link not found', _path);
    }

    return _symlinks[_path]!;
  }

  @override
  Link createSync(String target, {bool recursive = false}) {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('createSync:$_path')) {
      throw _failureScenarios['createSync:$_path']!;
    }

    if (recursive) {
      // Create parent directories if needed
      var parent = p.dirname(_path);
      if (parent != _path && parent != '.' && parent != '/') {
        // This needs to use the mock directory system
        throw UnimplementedError(
          'Recursive link creation not supported in MockLink. '
          'Create parent directories separately.',
        );
      }
    }

    _exists = true;
    _target = target;
    _symlinks[_path] = target;
    return this;
  }

  @override
  void deleteSync({bool recursive = false}) {
    // Check for failure scenarios
    if (_failureScenarios.containsKey('deleteSync:$_path')) {
      throw _failureScenarios['deleteSync:$_path']!;
    }

    if (!_exists || !_symlinks.containsKey(_path)) {
      throw FileSystemException('Link not found', _path);
    }

    _exists = false;
    _target = null;
    _symlinks.remove(_path);
  }

  @override
  Directory get parent => Directory(p.dirname(_path));

  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Method ${invocation.memberName} not implemented in MockLink',
    );
  }
}

/// A factory class to create mock file system objects
class MockFileSystem {
  final Map<String, MockFile> _files = {};
  final Map<String, MockDirectory> _directories = {};
  final Map<String, String> _symlinks = {};
  final Map<String, Exception> _failureScenarios = {};

  /// Creates a mock file
  File file(String path) {
    return _files.putIfAbsent(
      path,
      () => MockFile(path, _files, _directories, _symlinks, _failureScenarios),
    );
  }

  /// Creates a mock directory
  Directory directory(String path) {
    return _directories.putIfAbsent(
      path,
      () => MockDirectory(
          path, _files, _directories, _symlinks, _failureScenarios),
    );
  }

  /// Creates a mock link
  Link link(String path) {
    return MockLink(path, _symlinks, _failureScenarios);
  }

  /// Simulates a failure for a specific operation
  void simulateFailure(String pathAndOperation, Exception exception) {
    _failureScenarios[pathAndOperation] = exception;
  }

  /// Clears all simulated failures
  void clearFailureScenarios() {
    _failureScenarios.clear();
  }

  /// Resets the mock file system, clearing all files, directories, symlinks, and failure scenarios
  void reset() {
    _files.clear();
    _directories.clear();
    _symlinks.clear();
    _failureScenarios.clear();
  }
}

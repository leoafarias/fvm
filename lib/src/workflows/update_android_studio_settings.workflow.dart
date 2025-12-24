import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../models/project_model.dart';
import '../utils/constants.dart';
import 'update_project_references.workflow.dart';
import 'workflow.dart';

class UpdateAndroidStudioSettingsWorkflow extends Workflow {
  const UpdateAndroidStudioSettingsWorkflow(super.context);

  Future<void> call(Project project) async {
    final shouldUpdate = project.config?.updateAndroidStudioSettings ?? true;
    final ideaDir = Directory(p.join(project.path, '.idea'));

    if (!shouldUpdate) {
      logger.debug(
        '$kPackageName does not manage Android Studio settings for this project.',
      );

      if (ideaDir.existsSync()) {
        logger.warn(
          'You are using Android Studio, but $kPackageName is '
          'not managing Android Studio settings for this project. '
          'Please remove "updateAndroidStudioSettings: false" from '
          '$kFvmConfigFileName',
        );
      }

      return;
    }

    if (!ideaDir.existsSync()) {
      // Nothing to do for non-IDEA projects.
      logger.debug('Android Studio: .idea directory not found. Skipping.');

      return;
    }

    final flutterLink = Directory(
      p.join(
          project.localFvmPath, UpdateProjectReferencesWorkflow.flutterSdkLink),
    );
    if (!flutterLink.existsSync()) {
      logger.warn('Android Studio: .fvm/flutter_sdk not found. Skipping.');

      return;
    }

    final flutterReal = _safeResolve(flutterLink);
    if (flutterReal == null) {
      logger.warn(
        'Android Studio: failed to resolve .fvm/flutter_sdk. Skipping.',
      );

      return;
    }

    const dartMacro = r'$PROJECT_DIR$/.fvm/flutter_sdk/bin/cache/dart-sdk';

    final updates = <_PlannedEdit>[];

    // Use the symlink path, not the resolved path. This allows Android Studio
    // to automatically use the correct SDK when the symlink target changes
    // (e.g., when switching Flutter versions via 'fvm use').
    updates.addAll(await _planFlutterSettingsWrites(ideaDir, flutterLink.path));
    updates.addAll(await _planDartLibraryWrites(ideaDir, dartMacro));

    if (updates.isEmpty) {
      logger.info('Android Studio: already in sync.');

      return;
    }

    final grouped = _groupByFile(updates);
    for (final entry in grouped.entries) {
      final file = entry.key;
      final edits = entry.value;

      final original = await file.readAsString();
      final backup = File('${file.path}.fvm.bak');
      await backup.writeAsString(original);

      final updated = _applyEdits(original, edits);
      await file.writeAsString(updated);
      logger.info(
        'Android Studio: updated ${_rel(project.path, file.path)} '
        '(backup: ${_rel(project.path, backup.path)})',
      );

      final check = await file.readAsString();
      if (!_validatePostWrite(check, edits)) {
        logger.warn(
          'Android Studio: validation failed for ${file.path}. '
          'Backup saved at ${backup.path}.',
        );
      }
    }
  }

  Future<List<_PlannedEdit>> _planFlutterSettingsWrites(
    Directory ideaDir,
    String flutterReal,
  ) async {
    final candidates = await _scanXmlFiles(ideaDir);
    final edits = <_PlannedEdit>[];

    for (final file in candidates) {
      final text = await file.readAsString();
      if (!text.contains('FlutterSettings')) continue;

      final optRe = RegExp(
        r'(<component\s+name="FlutterSettings"[^>]*>[\s\S]*?)'
        r'(<option\s+name="FLUTTER_SDK_PATH"\s+value=")([^"]*)("([^>]*?)/?>)',
        multiLine: true,
      );
      final matches = optRe.allMatches(text).toList();

      if (matches.isNotEmpty) {
        for (final match in matches) {
          final current = match.group(3) ?? '';
          if (current == flutterReal) continue;

          final prefixLength =
              (match.group(1)?.length ?? 0) + (match.group(2)?.length ?? 0);
          final start = match.start + prefixLength;
          edits.add(
            _PlannedEdit(
              file: file,
              start: start,
              end: start + current.length,
              replacement: flutterReal,
              intent: _Intent.flutterSettingsPath,
            ),
          );
        }
        continue;
      }

      final compOpenRe = RegExp(
        r'(<component\s+name="FlutterSettings"[^>]*>)',
        multiLine: true,
      );
      final compMatch = compOpenRe.firstMatch(text);
      if (compMatch != null) {
        final insertion =
            '\n  <option name="FLUTTER_SDK_PATH" value="$flutterReal" />\n';
        edits.add(
          _PlannedEdit(
            file: file,
            start: compMatch.end,
            end: compMatch.end,
            replacement: insertion,
            intent: _Intent.flutterSettingsPathAdd,
          ),
        );
        continue;
      }

      final pretty = _rewriteFlutterSettingsDom(text, flutterReal);
      if (pretty != null) {
        edits.add(
          _PlannedEdit.replaceWholeFile(
            file,
            pretty,
            _Intent.flutterSettingsDomFallback,
          ),
        );
      }
    }

    return edits;
  }

  Future<List<_PlannedEdit>> _planDartLibraryWrites(
    Directory ideaDir,
    String dartMacro,
  ) async {
    final libFile = File(p.join(ideaDir.path, 'libraries', 'Dart_SDK.xml'));
    if (!libFile.existsSync()) return const [];

    final text = await libFile.readAsString();
    final urlRe = RegExp(r'url="([^"]+)"');
    final edits = <_PlannedEdit>[];

    for (final match in urlRe.allMatches(text)) {
      final url = match.group(1)!;

      if (url.contains('/.fvm/flutter_sdk/bin/cache/dart-sdk')) {
        continue;
      }

      final newUrl = _rewriteDartUrl(url, dartMacro);
      if (newUrl == url) continue;

      final start = match.start + 'url="'.length;
      edits.add(
        _PlannedEdit(
          file: libFile,
          start: start,
          end: start + url.length,
          replacement: newUrl,
          intent: _Intent.dartLibraryUrl,
        ),
      );
    }

    return edits;
  }

  String? _rewriteFlutterSettingsDom(String text, String flutterReal) {
    try {
      final doc = XmlDocument.parse(text);
      XmlElement? component;
      for (final element in doc.findAllElements('component')) {
        if (element.getAttribute('name') == 'FlutterSettings') {
          component = element;
          break;
        }
      }

      if (component == null) {
        return null;
      }

      XmlElement? option;
      for (final element in component.findElements('option')) {
        if (element.getAttribute('name') == 'FLUTTER_SDK_PATH') {
          option = element;
          break;
        }
      }

      if (option != null) {
        final current = option.getAttribute('value');
        if (current == flutterReal) {
          return null;
        }
        option.setAttribute('value', flutterReal);
      } else {
        option = XmlElement(
          XmlName('option'),
          [
            XmlAttribute(XmlName('name'), 'FLUTTER_SDK_PATH'),
            XmlAttribute(XmlName('value'), flutterReal),
          ],
        );
        component.children.add(option);
      }

      return doc.toXmlString(pretty: true, indent: '  ');
    } catch (_) {
      return null;
    }
  }

  String? _safeResolve(Directory link) {
    try {
      return link.resolveSymbolicLinksSync();
    } catch (_) {
      return null;
    }
  }

  String _rewriteDartUrl(String url, String dartMacro) {
    final index = url.indexOf('dart-sdk');
    if (index < 0) return url;

    final suffix = url.substring(index + 'dart-sdk'.length);

    if (url.startsWith('jar://')) {
      return 'jar://$dartMacro$suffix';
    }

    return 'file://$dartMacro$suffix';
  }

  Map<File, List<_PlannedEdit>> _groupByFile(List<_PlannedEdit> edits) {
    final grouped = <File, List<_PlannedEdit>>{};
    for (final edit in edits) {
      grouped.putIfAbsent(edit.file, () => []).add(edit);
    }

    for (final list in grouped.values) {
      list.sort((a, b) => b.start.compareTo(a.start));
    }

    return grouped;
  }

  String _applyEdits(String original, List<_PlannedEdit> edits) {
    var output = original;
    for (final edit in edits) {
      output = output.replaceRange(edit.start, edit.end, edit.replacement);
    }
    return output;
  }

  bool _validatePostWrite(String content, List<_PlannedEdit> edits) {
    for (final edit in edits) {
      if (!content.contains(edit.replacement)) {
        return false;
      }
    }

    return true;
  }

  Future<List<File>> _scanXmlFiles(Directory dir) async {
    final files = <File>[];
    await for (final entry in dir.list(recursive: true, followLinks: false)) {
      if (entry is File && entry.path.endsWith('.xml')) {
        files.add(entry);
      }
    }
    return files;
  }

  String _rel(String root, String path) => p.relative(path, from: root);
}

enum _Intent {
  flutterSettingsPath,
  flutterSettingsPathAdd,
  flutterSettingsDomFallback,
  dartLibraryUrl,
}

class _PlannedEdit {
  final File file;
  final int start;
  final int end;
  final String replacement;
  final _Intent intent;

  _PlannedEdit({
    required this.file,
    required this.start,
    required this.end,
    required this.replacement,
    required this.intent,
  });

  factory _PlannedEdit.replaceWholeFile(
    File file,
    String content,
    _Intent intent,
  ) {
    final text = file.readAsStringSync();
    return _PlannedEdit(
      file: file,
      start: 0,
      end: text.length,
      replacement: content,
      intent: intent,
    );
  }
}

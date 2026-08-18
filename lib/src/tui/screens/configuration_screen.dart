import 'dart:async';

import 'package:noir/noir.dart';

import '../fvm_tui_controller.dart';
import '../fvm_tui_models.dart';
import '../theme/fvm_tui_theme.dart';
import '../widgets/terminal_primitives.dart';

final class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({
    required this.controller,
    required this.onBack,
    super.key,
  });

  final FvmTuiController controller;
  final VoidCallback onBack;

  @override
  State<ConfigurationScreen> createState() => ConfigurationScreenState();
}

final class ConfigurationScreenState extends State<ConfigurationScreen> {
  static const _scopeOptions = [
    SelectOption(
      name: 'Global',
      description: 'User-wide defaults',
      value: ConfigurationScope.global,
    ),
    SelectOption(
      name: 'Project',
      description: 'Overrides in .fvmrc',
      value: ConfigurationScope.project,
    ),
  ];

  final _scopeFocus = FocusNode(debugLabel: 'configuration-scope');
  final _cachePathFocus = FocusNode(debugLabel: 'configuration-cache-path');
  final _gitCachePathFocus = FocusNode(
    debugLabel: 'configuration-git-cache-path',
  );
  late final TextEditingController _cachePathController;
  late final TextEditingController _gitCachePathController;
  final Set<TuiConfigurationField> _dirty = {};

  late ConfigurationScope _scope;
  late Set<TuiConfigurationField> _overriddenFields;
  late String _cachePath;
  late String _gitCachePath;
  late bool _runPubGetOnSdkChanges;
  late bool _updateVscodeSettings;
  late bool _updateGitIgnore;
  late bool _updateMelosSettings;
  late bool _useGitCache;
  bool? _updateCheckEnabled;
  bool _globalUpdateCheckEnabled = true;
  TuiConfigurationField? _editingPath;
  var _selectedFieldIndex = 0;

  @override
  void initState() {
    super.initState();
    final snapshot = widget.controller.configuration!;
    _cachePathController = TextEditingController(text: snapshot.cachePath);
    _gitCachePathController = TextEditingController(
      text: snapshot.gitCachePath,
    );
    _applySnapshot(snapshot);
  }

  void _applySnapshot(TuiConfiguration snapshot) {
    _scope = snapshot.scope;
    _overriddenFields = {...snapshot.overriddenFields};
    _cachePath = snapshot.cachePath;
    _gitCachePath = snapshot.gitCachePath;
    _runPubGetOnSdkChanges = snapshot.runPubGetOnSdkChanges;
    _updateVscodeSettings = snapshot.updateVscodeSettings;
    _updateGitIgnore = snapshot.updateGitIgnore;
    _updateMelosSettings = snapshot.updateMelosSettings;
    _useGitCache = snapshot.useGitCache;
    _updateCheckEnabled = snapshot.updateCheckEnabled;
    if (snapshot.updateCheckEnabled case final enabled?) {
      _globalUpdateCheckEnabled = enabled;
    }
    _cachePathController.text = snapshot.cachePath;
    _gitCachePathController.text = snapshot.gitCachePath;
    _dirty.clear();
    _editingPath = null;
  }

  String fieldLabel(TuiConfigurationField field) {
    final base = switch (field) {
      TuiConfigurationField.cachePath => 'Cache path',
      TuiConfigurationField.gitCachePath => 'Git cache path',
      TuiConfigurationField.runPubGetOnSdkChanges =>
        'Run pub get on SDK changes',
      TuiConfigurationField.updateVscodeSettings => 'Update VS Code settings',
      TuiConfigurationField.updateGitIgnore => 'Update .gitignore',
      TuiConfigurationField.updateMelosSettings => 'Update Melos settings',
      TuiConfigurationField.useGitCache => 'Use Git cache',
      TuiConfigurationField.updateCheckEnabled => 'Check for FVM updates',
    };
    if (_scope == ConfigurationScope.project &&
        field == TuiConfigurationField.updateCheckEnabled) {
      return '$base (global, read-only)';
    }
    if (_scope == ConfigurationScope.project &&
        !_overriddenFields.contains(field)) {
      return '$base (inherited)';
    }

    return base;
  }

  Future<void> switchScope(ConfigurationScope scope) async {
    if (scope == _scope) return;
    await widget.controller.loadConfiguration(scope);
    if (!mounted || widget.controller.configuration == null) return;
    setState(() => _applySnapshot(widget.controller.configuration!));
  }

  void toggle(TuiConfigurationField field) {
    if (!mounted ||
        field == TuiConfigurationField.cachePath ||
        field == TuiConfigurationField.gitCachePath ||
        (_scope == ConfigurationScope.project &&
            field == TuiConfigurationField.updateCheckEnabled)) {
      return;
    }
    setState(() {
      switch (field) {
        case TuiConfigurationField.runPubGetOnSdkChanges:
          _runPubGetOnSdkChanges = !_runPubGetOnSdkChanges;
        case TuiConfigurationField.updateVscodeSettings:
          _updateVscodeSettings = !_updateVscodeSettings;
        case TuiConfigurationField.updateGitIgnore:
          _updateGitIgnore = !_updateGitIgnore;
        case TuiConfigurationField.updateMelosSettings:
          _updateMelosSettings = !_updateMelosSettings;
        case TuiConfigurationField.useGitCache:
          _useGitCache = !_useGitCache;
        case TuiConfigurationField.updateCheckEnabled:
          _updateCheckEnabled = !(_updateCheckEnabled ?? true);
        case TuiConfigurationField.cachePath ||
            TuiConfigurationField.gitCachePath:
          break;
      }
      _dirty.add(field);
    });
  }

  void beginPathEdit(TuiConfigurationField field) {
    if (!mounted ||
        (field != TuiConfigurationField.cachePath &&
            field != TuiConfigurationField.gitCachePath)) {
      return;
    }
    setState(() => _editingPath = field);
  }

  void setPathText(TuiConfigurationField field, String value) {
    switch (field) {
      case TuiConfigurationField.cachePath:
        _cachePathController.text = value;
      case TuiConfigurationField.gitCachePath:
        _gitCachePathController.text = value;
      case TuiConfigurationField.runPubGetOnSdkChanges ||
          TuiConfigurationField.updateVscodeSettings ||
          TuiConfigurationField.updateGitIgnore ||
          TuiConfigurationField.updateMelosSettings ||
          TuiConfigurationField.useGitCache ||
          TuiConfigurationField.updateCheckEnabled:
        break;
    }
  }

  void commitPathEdit() {
    final field = _editingPath;
    if (!mounted || field == null) return;
    setState(() {
      if (field == TuiConfigurationField.cachePath) {
        _cachePath = _cachePathController.text;
      } else {
        _gitCachePath = _gitCachePathController.text;
      }
      _dirty.add(field);
      _editingPath = null;
    });
    if (_scopeFocus.isAttached) _scopeFocus.requestFocus();
  }

  void _cancelPathEdit() {
    _cachePathController.text = _cachePath;
    _gitCachePathController.text = _gitCachePath;
    setState(() => _editingPath = null);
    if (_scopeFocus.isAttached) _scopeFocus.requestFocus();
  }

  Future<void> save() async {
    await widget.controller.saveConfiguration((
      scope: _scope,
      cachePath: _dirty.contains(TuiConfigurationField.cachePath)
          ? _cachePath
          : null,
      gitCachePath: _dirty.contains(TuiConfigurationField.gitCachePath)
          ? _gitCachePath
          : null,
      runPubGetOnSdkChanges:
          _dirty.contains(TuiConfigurationField.runPubGetOnSdkChanges)
          ? _runPubGetOnSdkChanges
          : null,
      updateVscodeSettings:
          _dirty.contains(TuiConfigurationField.updateVscodeSettings)
          ? _updateVscodeSettings
          : null,
      updateGitIgnore: _dirty.contains(TuiConfigurationField.updateGitIgnore)
          ? _updateGitIgnore
          : null,
      updateMelosSettings:
          _dirty.contains(TuiConfigurationField.updateMelosSettings)
          ? _updateMelosSettings
          : null,
      useGitCache: _dirty.contains(TuiConfigurationField.useGitCache)
          ? _useGitCache
          : null,
      updateCheckEnabled:
          _scope == ConfigurationScope.global &&
              _dirty.contains(TuiConfigurationField.updateCheckEnabled)
          ? _updateCheckEnabled
          : null,
    ));
    if (!mounted || widget.controller.configuration == null) return;
    setState(() => _applySnapshot(widget.controller.configuration!));
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!event.isPress) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_editingPath != null) {
        _cancelPathEdit();
      } else {
        widget.onBack();
      }

      return KeyEventResult.handled;
    }
    if (_editingPath != null) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      unawaited(switchScope(ConfigurationScope.global));

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      unawaited(switchScope(ConfigurationScope.project));

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(
        () => _selectedFieldIndex = (_selectedFieldIndex - 1).clamp(0, 7),
      );

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(
        () => _selectedFieldIndex = (_selectedFieldIndex + 1).clamp(0, 7),
      );

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      toggle(TuiConfigurationField.values[_selectedFieldIndex]);

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final field = TuiConfigurationField.values[_selectedFieldIndex];
      switch (field) {
        case TuiConfigurationField.cachePath ||
            TuiConfigurationField.gitCachePath:
          beginPathEdit(field);
        case TuiConfigurationField.runPubGetOnSdkChanges ||
            TuiConfigurationField.updateVscodeSettings ||
            TuiConfigurationField.updateGitIgnore ||
            TuiConfigurationField.updateMelosSettings ||
            TuiConfigurationField.useGitCache ||
            TuiConfigurationField.updateCheckEnabled:
          unawaited(save());
      }

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _pathField(TuiConfigurationField field) {
    final editing = _editingPath == field;
    final controller = field == TuiConfigurationField.cachePath
        ? _cachePathController
        : _gitCachePathController;
    final focusNode = field == TuiConfigurationField.cachePath
        ? _cachePathFocus
        : _gitCachePathFocus;
    if (editing) {
      return TextInput(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        onSubmit: commitPathEdit,
        backgroundColor: FvmTuiColors.selected,
      );
    }

    return DetailRow(label: fieldLabel(field), value: controller.text);
  }

  bool _value(TuiConfigurationField field) => switch (field) {
    TuiConfigurationField.runPubGetOnSdkChanges => _runPubGetOnSdkChanges,
    TuiConfigurationField.updateVscodeSettings => _updateVscodeSettings,
    TuiConfigurationField.updateGitIgnore => _updateGitIgnore,
    TuiConfigurationField.updateMelosSettings => _updateMelosSettings,
    TuiConfigurationField.useGitCache => _useGitCache,
    TuiConfigurationField.updateCheckEnabled =>
      _scope == ConfigurationScope.global
          ? (_updateCheckEnabled ?? true)
          : _globalUpdateCheckEnabled,
    TuiConfigurationField.cachePath ||
    TuiConfigurationField.gitCachePath => false,
  };

  @override
  void dispose() {
    _scopeFocus.dispose();
    _cachePathFocus.dispose();
    _gitCachePathFocus.dispose();
    _cachePathController.dispose();
    _gitCachePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: _handleKey,
    child: ScrollBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 1,
        children: [
          Text('Configuration', style: FvmTuiTextStyles.heading),
          Select<ConfigurationScope>(
            focusNode: _scopeFocus,
            height: 2,
            selectedIndex: _scope.index,
            options: _scopeOptions,
            onSelect: (index, option) {
              final scope = option.value;
              if (scope != null) unawaited(switchScope(scope));
            },
          ),
          _pathField(TuiConfigurationField.cachePath),
          _pathField(TuiConfigurationField.gitCachePath),
          for (final field in TuiConfigurationField.values.skip(2))
            ToggleRow(
              label: fieldLabel(field),
              value: _value(field),
              focused: _selectedFieldIndex == field.index,
            ),
          const KeyHint(keyLabel: 'Left/Right', description: 'scope'),
          const KeyHint(keyLabel: 'Space', description: 'toggle'),
          const KeyHint(keyLabel: 'Enter', description: 'edit or save'),
          const KeyHint(keyLabel: 'Escape', description: 'cancel or back'),
        ],
      ),
    ),
  );
}

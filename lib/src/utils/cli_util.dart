// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities to return the Dart SDK location.

import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:path/path.dart' as path;

/// Return the path to the current Dart SDK.
String getSdkPath() => path.dirname(path.dirname(Platform.resolvedExecutable));

final _env = Platform.environment;

String applicationConfigHome(String productName) =>
    path.join(_configHome, productName);

String get _configHome {
  if (Platform.isWindows) {
    final appdata = _env['APPDATA'] ?? kUserHome;

    return appdata;
  }

  if (Platform.isMacOS) {
    return path.join(kUserHome, 'Library', 'Application Support');
  }

  if (Platform.isLinux) {
    final xdgConfigHome = _env['XDG_CONFIG_HOME'];
    if (xdgConfigHome != null) {
      return xdgConfigHome;
    }
    // XDG Base Directory Specification says to use $HOME/.config/ when
    // $XDG_CONFIG_HOME isn't defined.
    return path.join(kUserHome, '.config');
  }

  // We have no guidelines, perhaps we should just do: $HOME/.config/
  // same as XDG specification would specify as fallback.
  return path.join(kUserHome, '.config');
}

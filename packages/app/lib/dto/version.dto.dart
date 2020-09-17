import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';
import 'package:path/path.dart';

abstract class VersionDto {
  final String name;
  bool isInstalled;
  Release release;
  bool needSetup;
  bool isChannel;

  /// Directory of the version if its installed
  Directory installedDir;
  VersionDto({
    @required this.name,
    @required this.release,
    @required this.isInstalled,
    @required this.needSetup,
    this.isChannel = false,
  }) : installedDir = Directory(join(kVersionsDir.path, name));
}

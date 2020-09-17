import 'package:fvm_app/dto/version.dto.dart';
import 'package:flutter/material.dart';
import 'package:fvm/fvm.dart';

class ReleaseDto extends VersionDto {
  ReleaseDto({
    @required String name,
    @required bool isInstalled,
    @required Release release,
    @required bool needSetup,
  }) : super(
          name: name,
          release: release,
          isInstalled: isInstalled,
          needSetup: needSetup,
        );
}

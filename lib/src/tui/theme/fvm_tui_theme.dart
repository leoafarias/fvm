import 'package:noir/noir.dart';

import '../fvm_tui_models.dart';

abstract final class FvmTuiColors {
  static final canvas = Color.fromHex('#0D0C12');
  static final panel = Color.fromHex('#18151F');
  static final surface = Color.fromHex('#211E29');
  static final selected = Color.fromHex('#241A3A');
  static final border = Color.fromHex('#393442');
  static final muted = Color.fromHex('#9A93A4');
  static final primary = Color.fromHex('#F4F1F7');
  static final violet = Color.fromHex('#A589E8');
  static final info = Color.fromHex('#65D1E5');
  static final success = Color.fromHex('#58D68D');
  static final warning = Color.fromHex('#F2C14E');
  static final error = Color.fromHex('#FF6B72');
}

abstract final class FvmTuiTextStyles {
  static final body = TextStyle(color: FvmTuiColors.primary);
  static final muted = TextStyle(color: FvmTuiColors.muted);
  static final heading = TextStyle(
    color: FvmTuiColors.primary,
    fontWeight: FontWeight.bold,
  );
  static final accent = TextStyle(
    color: FvmTuiColors.violet,
    fontWeight: FontWeight.bold,
  );

  static TextStyle forTone(TuiTone tone) => TextStyle(
    color: switch (tone) {
      TuiTone.neutral => FvmTuiColors.muted,
      TuiTone.info => FvmTuiColors.info,
      TuiTone.success => FvmTuiColors.success,
      TuiTone.warning => FvmTuiColors.warning,
      TuiTone.error => FvmTuiColors.error,
    },
  );
}

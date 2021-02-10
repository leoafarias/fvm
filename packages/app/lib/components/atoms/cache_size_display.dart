import 'package:fvm_app/components/atoms/typography.dart';
import 'package:fvm_app/providers/fvm_cache.provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class CacheSizeDisplay extends HookWidget {
  const CacheSizeDisplay({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cacheSize = useProvider(fvmCacheSizeProvider).state;

    if (cacheSize == null) {
      return const SizedBox(height: 0);
    }

    return Container(
      child: TypographyCaption('Storage $cacheSize'),
    );
  }
}

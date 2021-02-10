import 'dart:io';

import 'package:fvm_app/dto/version.dto.dart';
import 'package:date_time_format/date_time_format.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class CacheDateDisplay extends HookWidget {
  final VersionDto version;
  const CacheDateDisplay(this.version, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cacheDirStat = useState<FileStat>();

    void setCacheDir() async {
      if (version != null && version.isInstalled == true) {
        cacheDirStat.value = await version.installedDir.stat();
      }
    }

    useEffect(() {
      setCacheDir();
      return;
    }, [version]);

    if (cacheDirStat.value == null) {
      return const SizedBox(height: 0);
    }

    return Text(DateTimeFormat.format(
      cacheDirStat.value.changed,
      format: AmericanDateFormats.abbr,
    ));
  }
}

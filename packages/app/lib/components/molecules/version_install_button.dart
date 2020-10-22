import 'package:fvm_app/dto/version.dto.dart';

import 'package:fvm_app/providers/fvm_queue.provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class VersionInstallButton extends HookWidget {
  final VersionDto version;
  final bool expanded;
  const VersionInstallButton(this.version, {this.expanded = false, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isQueued = useState(false);
    final hovering = useState(false);
    final queueProvider = useProvider(fvmQueueProvider.state);

    useEffect(() {
      final isInstalling = queueProvider.activeItem != null &&
          queueProvider.activeItem.name == version.name;

      if (isInstalling) {
        isQueued.value = true;
        return;
      }

      final queued = queueProvider.queue.firstWhere(
        (item) => item.name == version.name,
        orElse: () => null,
      );

      isQueued.value = queued != null;
      return;
    }, [queueProvider]);

    Future<void> onInstall() async {
      isQueued.value = true;
      // Add it to queue for installation
      context.read(fvmQueueProvider).install(version.name);
    }

    Widget installIcon() {
      if ((isQueued.value && !version.isInstalled)) {
        return const SizedBox(
          height: 20,
          width: 20,
          child: SpinKitFadingFour(
            size: 15,
            color: Colors.cyan,
          ),
        );
      }

      if (version.isInstalled) {
        return const Icon(Icons.check, size: 20);
      }

      return const Icon(Icons.arrow_downward, size: 20);
    }

    Widget collapsedButton() {
      return SizedBox(
        height: 50,
        width: 50,
        child: Center(
          child: FlatButton(
            color: Colors.white10,
            onPressed: version.isInstalled ? () {} : onInstall,
            child: installIcon(),
          ),
        ),
      );
    }

    Widget expandedButton() {
      return Container(
        width: 100,
        child: FlatButton.icon(
          color: Colors.white10,
          onPressed: version.isInstalled ? () {} : onInstall,
          icon: installIcon(),
          label: Text(
            version.isInstalled ? 'Install' : 'Installed',
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
      );
    }

    return MouseRegion(
      onHover: (_) {
        if (!hovering.value) {
          hovering.value = true;
        }
      },
      onExit: (_) {
        if (hovering.value) {
          hovering.value = false;
        }
      },
      child: Opacity(
        opacity: version.isInstalled ? 0.3 : 1,
        child: expanded ? expandedButton() : collapsedButton(),
      ),
    );
  }
}

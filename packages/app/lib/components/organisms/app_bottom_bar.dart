import 'package:fvm_app/components/atoms/console.dart';

import 'package:fvm_app/providers/fvm_queue.provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AppBottomBar extends HookWidget {
  const AppBottomBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actions = useProvider(fvmQueueProvider.state);
    final expand = useState(false);
    final processing = actions.activeItem != null;
    void toggleExpand() {
      expand.value = !expand.value;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      constraints: expand.value && processing
          ? const BoxConstraints(maxHeight: 141)
          : const BoxConstraints(maxHeight: 41),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          actions.activeItem != null
              ? const LinearProgressIndicator(minHeight: 1)
              : const Divider(height: 1),
          Expanded(
            child: Console(
              expand: expand.value,
              onExpand: toggleExpand,
              processing: processing,
            ),
          )
        ],
      ),
    );
  }
}

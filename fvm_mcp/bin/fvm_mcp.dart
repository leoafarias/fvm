import 'dart:io';

import 'package:dart_mcp/stdio.dart';
import 'package:fvm_mcp/src/server.dart';

Future<void> main() async {
  try {
    final channel = stdioChannel(input: stdin, output: stdout);
    final server = await FvmMcpServer.start(channel: channel);
    // Exit when the client shuts down.
    await server.done;
  } catch (e, s) {
    stderr.writeln(e);
    stderr.writeln(s);
    exitCode = 1;
  }
}

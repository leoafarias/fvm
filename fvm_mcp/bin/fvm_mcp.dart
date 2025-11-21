import 'dart:io';

import 'package:dart_mcp/stdio.dart';
import 'package:fvm_mcp/src/server.dart';

Future<void> main() async {
  final channel = stdioChannel(input: stdin, output: stdout);
  final server = await FvmMcpServer.start(channel: channel);
  // Exit when the client shuts down.
  await server.done;
}

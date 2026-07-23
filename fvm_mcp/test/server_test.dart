import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/client.dart';
import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String fakeFvm;
  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('fvm_mcp_server_');
    fakeFvm = '${tempDir.path}${Platform.pathSeparator}'
        '${Platform.isWindows ? 'fvm.exe' : 'fvm'}';
    final result = await Process.run(
        Platform.resolvedExecutable,
        [
          'compile',
          'exe',
          'test/bin/fake_fvm.dart',
          '-o',
          fakeFvm,
        ],
        runInShell: Platform.isWindows);
    if (result.exitCode != 0) {
      fail('Failed to compile fake FVM:\n${result.stdout}\n${result.stderr}');
    }
  });

  tearDownAll(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });
  test('registers and translates the supported tool contract', () async {
    final harness = await _ServerHarness.start(fakeFvm, version: '4.1.2');
    addTearDown(harness.close);

    final tools = (await harness.connection.listTools()).tools;
    expect(tools.map((tool) => tool.name).toList()..sort(), [
      'fvm.api.context',
      'fvm.api.list',
      'fvm.api.project',
      'fvm.api.releases',
      'fvm.dart',
      'fvm.exec',
      'fvm.flutter',
      'fvm.global',
      'fvm.install',
      'fvm.remove',
      'fvm.spawn',
      'fvm.use',
    ]);

    final releases = tools.singleWhere(
      (tool) => tool.name == 'fvm.api.releases',
    );
    expect(releases.toolAnnotations?.readOnlyHint, isTrue);
    final flutter = tools.singleWhere((tool) => tool.name == 'fvm.flutter');
    expect(flutter.toolAnnotations?.openWorldHint, isTrue);

    final releaseCall = await harness.connection.callTool(
      CallToolRequest(
        name: releases.name,
        arguments: {'limit': 5, 'filter_channel': 'beta', 'compress': true},
      ),
    );
    expect(_invocation(releaseCall), {
      'hadSkipInput': false,
      'args': [
        'api',
        'releases',
        '--limit',
        '5',
        '--filter-channel',
        'beta',
        '--compress',
      ],
    });

    final flutterCall = await harness.connection.callTool(
      CallToolRequest(
        name: flutter.name,
        arguments: {
          'args': ['--version'],
        },
      ),
    );
    expect(_invocation(flutterCall), {
      'hadSkipInput': true,
      'args': ['flutter', '--version'],
    });

    final invalidFlutterCall = await harness.connection.callTool(
      CallToolRequest(
        name: flutter.name,
        arguments: {
          'args': ['--version', 42],
        },
      ),
    );
    expect(invalidFlutterCall.isError, isTrue);

    final missingDirectory = '${Directory.systemTemp.path}'
        '${Platform.pathSeparator}fvm_mcp_missing_${DateTime.now().microsecondsSinceEpoch}';
    final failure = await harness.connection.callTool(
      CallToolRequest(name: flutter.name, arguments: {'cwd': missingDirectory}),
    );
    expect(failure.isError, isTrue);
    expect(
      (failure.content.single as TextContent).text,
      'Internal error while running fvm.flutter.',
    );
  });

  test('gates JSON and mutating tools for older FVM versions', () async {
    final harness = await _ServerHarness.start(fakeFvm, version: '3.0.0');
    addTearDown(harness.close);

    final tools = await harness.connection.listTools();
    expect(tools.tools.map((tool) => tool.name).toList()..sort(), [
      'fvm.dart',
      'fvm.exec',
      'fvm.flutter',
      'fvm.spawn',
    ]);
  });
}

Map<String, Object?> _invocation(CallToolResult result) {
  final content = result.content.single as TextContent;
  return (jsonDecode(content.text) as Map).cast<String, Object?>();
}

final class _ServerHarness {
  final Process process;
  final MCPClient client;
  final ServerConnection connection;

  const _ServerHarness({
    required this.process,
    required this.client,
    required this.connection,
  });

  static Future<_ServerHarness> start(
    String fakeFvm, {
    required String version,
  }) async {
    final separator = Platform.isWindows ? ';' : ':';
    final inheritedPath = Platform.environment['PATH'];
    final path = [
      File(fakeFvm).parent.path,
      if (inheritedPath != null) inheritedPath,
    ].join(separator);
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['run', 'bin/fvm_mcp.dart'],
      environment: {
        ...Platform.environment,
        'PATH': path,
        'FAKE_FVM_VERSION': version,
      },
    );
    final stderr = StringBuffer();
    process.stderr.transform(utf8.decoder).listen(stderr.write);
    final client = MCPClient(
      Implementation(name: 'fvm_mcp test client', version: '1.0.0'),
    );
    final connection = client.connectServer(
      stdioChannel(input: process.stdout, output: process.stdin),
    );

    try {
      await connection
          .initialize(
            InitializeRequest(
              protocolVersion: ProtocolVersion.latestSupported,
              capabilities: client.capabilities,
              clientInfo: client.implementation,
            ),
          )
          .timeout(const Duration(seconds: 15));
      connection.notifyInitialized();
    } on Object {
      process.kill();
      fail('Failed to initialize fvm_mcp:\n$stderr');
    }

    return _ServerHarness(
      process: process,
      client: client,
      connection: connection,
    );
  }

  Future<void> close() async {
    await client.shutdown();
    try {
      await process.exitCode.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      process.kill();
      await process.exitCode;
    }
  }
}

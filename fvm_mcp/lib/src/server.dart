// @dart=3.5

import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:stream_channel/stream_channel.dart';

import 'arg_utils.dart';
import 'process_runner.dart';
import 'version.dart';

/// MCP server exposing FVM as tools.
/// Requires FVM on PATH. Tools are gated by detected version.
base class FvmMcpServer extends MCPServer with ToolsSupport {
  final FvmVersion fvm;
  final ProcessRunner _runner;

  FvmMcpServer._({
    required Implementation implementation,
    required StreamChannel<String> channel,
    required this.fvm,
    required ProcessRunner runner,
  })  : _runner = runner,
        super.fromStreamChannel(
          channel,
          implementation: implementation,
          instructions:
              'Use tools under the fvm.* namespace. Read-only JSON via fvm api; '
              'mutations are non-interactive where supported. '
              'This server mirrors your installed FVM ${implementation.version}.',
        );

  /// Create, detect FVM version, then return a ready server.
  static Future<FvmMcpServer> start({
    required StreamChannel<String> channel,
  }) async {
    final detected = await detectFvmVersion();
    final impl = Implementation(name: 'fvm-mcp', version: detected.raw);
    final server = FvmMcpServer._(
      implementation: impl,
      channel: channel,
      fvm: detected,
      runner: ProcessRunner(
        exe: 'fvm',
        hasSkipInput: detected.supportsSkipInput,
      ),
    );
    server._runner.bindNotifier(server.notifyProgress);
    return server.._registerTools();
  }

  // ---- Registration ----

  void _registerTools() {
    // JSON API (>= 3.1.2)
    if (fvm.supportsJsonApi) {
      _tool(
        name: 'fvm.api.list',
        desc: 'JSON: list cached Flutter SDKs',
        schema: ObjectSchema(properties: {
          'compress': BooleanSchema(),
          'skip_size_calculation': BooleanSchema(),
        }, additionalProperties: false),
        run: (call) => _runner.runJsonApi(
          [
            'api',
            'list',
            ...flag(call, 'compress', '--compress'),
            ...flag(call, 'skip_size_calculation', '--skip-size-calculation'),
          ],
          meta: call.meta,
        ),
      );

      _tool(
        name: 'fvm.api.releases',
        desc: 'JSON: available Flutter releases',
        schema: ObjectSchema(properties: {
          'compress': BooleanSchema(),
          'limit': IntegerSchema(minimum: 1),
          'filter_channel': StringSchema(
            description: 'Optional channel filter: stable|beta|dev',
          ),
        }, additionalProperties: false),
        run: (call) => _runner.runJsonApi(
          [
            'api',
            'releases',
            ...opt(call, 'limit', (v) => ['--limit', '$v']),
            ...opt(call, 'filter_channel', (v) => ['--filter-channel', '$v']),
            ...flag(call, 'compress', '--compress'),
          ],
          meta: call.meta,
        ),
      );

      _tool(
        name: 'fvm.api.context',
        desc: 'JSON: FVM environment/context',
        schema: ObjectSchema(properties: {
          'compress': BooleanSchema(),
        }, additionalProperties: false),
        run: (call) => _runner.runJsonApi(
          [
            'api',
            'context',
            ...flag(call, 'compress', '--compress'),
          ],
          meta: call.meta,
        ),
      );

      _tool(
        name: 'fvm.api.project',
        desc: 'JSON: project config',
        schema: ObjectSchema(properties: {
          'path': StringSchema(),
          'compress': BooleanSchema(),
        }, additionalProperties: false),
        run: (call) => _runner.runJsonApi(
          [
            'api',
            'project',
            ...opt(call, 'path', (v) => ['--path', '$v']),
            ...flag(call, 'compress', '--compress'),
          ],
          meta: call.meta,
        ),
      );
    }

    // Mutating tools
    _tool(
      name: 'fvm.install',
      desc: 'Install a Flutter SDK into cache (state-changing)',
      schema: ObjectSchema(properties: {
        'version': StringSchema(),
        'setup': BooleanSchema(
          description: 'true -> --setup, false -> --no-setup (if supported)',
        ),
        'skip_pub_get': BooleanSchema(),
        'cwd': StringSchema(),
      }, additionalProperties: false),
      run: (call) => _runner.run(
        [
          'install',
          ...maybeOne(call, 'version'),
          ...when<bool>(call, 'setup', (s) => [s ? '--setup' : '--no-setup']),
          ...flag(call, 'skip_pub_get', '--skip-pub-get'),
        ],
        cwd: stringArg(call, 'cwd'),
        // installs can be long
        timeout: const Duration(minutes: 15),
        progressLabel: 'install',
        meta: call.meta,
      ),
    );

    _tool(
      name: 'fvm.remove',
      desc: 'Remove SDK(s) from cache (state-changing)',
      schema: ObjectSchema(properties: {
        'version': StringSchema(),
        'all': BooleanSchema(),
        'cwd': StringSchema(),
      }, additionalProperties: false),
      run: (call) {
        final all = boolArg(call, 'all') ?? false;
        final version = stringArg(call, 'version');
        if (!all && (version == null || version.isEmpty)) {
          return _error('Missing args: set "version" or "all=true".');
        }
        return _runner.run(
          [
            'remove',
            if (all) '--all' else ...[version!],
          ],
          cwd: stringArg(call, 'cwd'),
          timeout: const Duration(minutes: 5),
          progressLabel: 'remove',
          meta: call.meta,
        );
      },
    );

    _tool(
      name: 'fvm.use',
      desc: 'Set SDK for current project (state-changing)',
      schema: ObjectSchema(properties: {
        'version': StringSchema(),
        'force': BooleanSchema(),
        'pin': BooleanSchema(),
        'flavor': StringSchema(),
        'env': StringSchema(),
        'skip_setup': BooleanSchema(),
        'skip_pub_get': BooleanSchema(),
        'cwd': StringSchema(),
      }, additionalProperties: false),
      run: (call) => _runner.run(
        [
          'use',
          ...maybeOne(call, 'version'),
          ...flag(call, 'force', '--force'),
          ...flag(call, 'pin', '--pin'),
          ...opt(call, 'flavor', (v) => ['--flavor', '$v']),
          ...opt(call, 'env', (v) => ['--env', '$v']),
          ...flag(call, 'skip_setup', '--skip-setup'),
          ...flag(call, 'skip_pub_get', '--skip-pub-get'),
        ],
        cwd: stringArg(call, 'cwd'),
        timeout: const Duration(minutes: 10),
        progressLabel: 'use',
        meta: call.meta,
      ),
    );

    _tool(
      name: 'fvm.global',
      desc: 'Set/unlink global SDK (state-changing)',
      schema: ObjectSchema(properties: {
        'version': StringSchema(),
        'force': BooleanSchema(),
        'unlink': BooleanSchema(),
      }, additionalProperties: false),
      run: (call) => _runner.run(
        [
          'global',
          if (boolArg(call, 'unlink') == true)
            '--unlink'
          else
            ...maybeOne(call, 'version'),
          ...flag(call, 'force', '--force'),
        ],
        timeout: const Duration(minutes: 2),
        progressLabel: 'global',
        meta: call.meta,
      ),
    );

    // Proxies
    _tool(
      name: 'fvm.flutter',
      desc: 'Run flutter with the resolved project SDK',
      schema: ObjectSchema(properties: {
        'args': ListSchema(items: StringSchema()),
        'cwd': StringSchema(),
      }, additionalProperties: false),
      run: (call) => _runner.run(
        ['flutter', ...listArg(call, 'args')],
        cwd: stringArg(call, 'cwd'),
        timeout: const Duration(minutes: 10),
        progressLabel: 'flutter',
        meta: call.meta,
      ),
    );

    _tool(
      name: 'fvm.dart',
      desc: 'Run dart with the resolved project SDK',
      schema: ObjectSchema(properties: {
        'args': ListSchema(items: StringSchema()),
        'cwd': StringSchema(),
      }, additionalProperties: false),
      run: (call) => _runner.run(
        ['dart', ...listArg(call, 'args')],
        cwd: stringArg(call, 'cwd'),
        timeout: const Duration(minutes: 10),
        progressLabel: 'dart',
        meta: call.meta,
      ),
    );

    _tool(
      name: 'fvm.exec',
      desc: 'Execute a command under the project SDK environment',
      schema: ObjectSchema(
        required: ['command'],
        properties: {
          'command': StringSchema(),
          'args': ListSchema(items: StringSchema()),
          'cwd': StringSchema(),
        },
        additionalProperties: false,
      ),
      run: (call) => _runner.run(
        ['exec', stringArg(call, 'command')!, ...listArg(call, 'args')],
        cwd: stringArg(call, 'cwd'),
        timeout: const Duration(minutes: 10),
        progressLabel: 'exec',
        meta: call.meta,
      ),
    );

    _tool(
      name: 'fvm.spawn',
      desc: 'Run flutter <args> with a specific SDK version',
      schema: ObjectSchema(
        required: ['version'],
        properties: {
          'version': StringSchema(),
          'flutter_args': ListSchema(items: StringSchema()),
          'cwd': StringSchema(),
        },
        additionalProperties: false,
      ),
      run: (call) => _runner.run(
        [
          'spawn',
          stringArg(call, 'version')!,
          ...listArg(call, 'flutter_args')
        ],
        cwd: stringArg(call, 'cwd'),
        timeout: const Duration(minutes: 10),
        progressLabel: 'spawn',
        meta: call.meta,
      ),
    );
  }

  // Tool registration helper.
  void _tool({
    required String name,
    required String desc,
    required ObjectSchema schema,
    required Future<CallToolResult> Function(CallToolRequest call) run,
  }) {
    registerTool(
      Tool(name: name, description: desc, inputSchema: schema),
      (call) async {
        try {
          return await run(call);
        } catch (e, s) {
          return CallToolResult(
            isError: true,
            content: [TextContent(text: 'Unhandled error: $e\n$s')],
          );
        }
      },
    );
  }

  Future<CallToolResult> _error(String message) async => CallToolResult(
        isError: true,
        content: [TextContent(text: message)],
      );
}

# fvm_mcp

MCP server that mirrors the FVM CLI as tools (stdio transport). Read-only JSON endpoints are passed through verbatim; writes are non-interactive on FVM ≥ 3.2.

## Install / Run

```bash
dart pub get
dart run bin/fvm_mcp.dart
```

Your MCP client should launch this as a stdio server (`command: dart`, `args: ["run","bin/fvm_mcp.dart"]`), or you can embed it into FVM as `fvm mcp` (see below).

### Tools

- Read-only JSON: `fvm.api.list`, `fvm.api.releases`, `fvm.api.context`, `fvm.api.project`.
- Mutating (FVM ≥ 3.2.0): `fvm.install`, `fvm.remove`, `fvm.use`, `fvm.global`.
- Proxies: `fvm.flutter`, `fvm.dart`, `fvm.exec`, `fvm.spawn`.

JSON API flags and response fields follow the FVM docs. Command flags and routing order follow the FVM commands reference.

### Version Gates

- JSON API available since 3.1.0; api context fix in 3.1.2 → gate at ≥ 3.1.2.
- Mutating tools require non-interactive support via `--fvm-skip-input` (≥ 3.2.0).

### Embed into FVM (`fvm mcp`)

Add a subcommand to the FVM CLI that constructs a stdio channel and calls `FvmMcpServer.start(...)`. This keeps the MCP surface version-locked to the installed FVM.

```dart
// lib/src/commands/mcp_command.dart  (inside FVM CLI)
import 'dart:io';
import 'package:dart_mcp/stdio.dart';
import 'package:fvm_mcp/src/server.dart';
import 'package:args/command_runner.dart';

class McpCommand extends Command<int> {
  @override
  final name = 'mcp';
  @override
  final description = 'Start the embedded MCP server over stdio.';

  @override
  Future<int> run() async {
    final channel = stdioChannel(input: stdin, output: stdout);
    final server = await FvmMcpServer.start(channel: channel);
    await server.done;
    return 0;
  }
}

// In the CLI entry, add:  runner.addCommand(McpCommand());
```

### Safety

- Mutating tools are marked “state-changing”.
- `remove` supports specific `version` removal only.
- Proxies honor FVM’s routing order (project → ancestor → global → PATH).

## License

MIT

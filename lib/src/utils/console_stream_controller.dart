import 'dart:async';

import 'dart:io' as io;

final consoleController = ConsoleController();

class ConsoleController {
  bool isCli;

  final stdout = StreamController<List<int>>();
  final stderr = StreamController<List<int>>();
  ConsoleController() {
    isCli = io.stdin.hasTerminal;
  }

  io.Stdin get stdinSink {
    return isCli ? io.stdin : null;
  }

  StreamSink<List<int>> get stdoutSink {
    return isCli ? io.stdout : stdout.sink;
  }

  StreamSink<List<int>> get stderrSink {
    return isCli ? io.stderr : stderr.sink;
  }
}

// void inheritIO(Process process, {String prefix, bool lineBased = true}) {
//   if (lineBased) {
//     process.stdout
//         .transform(utf8.decoder)
//         .transform(LineSplitter())
//         .listen((String data) {
//       if (prefix != null) {
//         stdout.write(prefix);
//       }
//       stdout.writeln(data);
//     });

//     process.stderr
//         .transform(utf8.decoder)
//         .transform(LineSplitter())
//         .listen((String data) {
//       if (prefix != null) {
//         stderr.write(prefix);
//       }
//       stderr.writeln(data);
//     });
//   } else {
//     process.stdout.listen((data) => stdout.add(data));
//     process.stderr.listen((data) => stderr.add(data));
//   }
// }

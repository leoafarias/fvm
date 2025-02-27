import 'package:meta/meta.dart';

import '../services/logger_service.dart';
import '../utils/context.dart';

abstract class Workflow {
  final FVMContext _context;

  Workflow(this._context);

  @protected
  Logger get logger => _context.logger;

  @protected
  FVMContext get context => _context;
}

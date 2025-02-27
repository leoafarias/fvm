import 'package:meta/meta.dart';

import '../utils/context.dart';
import 'logger_service.dart';

abstract class Contextual {
  final FVMContext _context;
  late final Logger _logger;

  Contextual(this._context) : _logger = Logger.fromContext(_context);

  /// Gets context, if no context is passed will get from scope
  @protected
  FVMContext get context => _context;

  @protected
  Logger get logger => _logger;
}

import 'package:meta/meta.dart';

import '../utils/context.dart';
import 'logger_service.dart';

abstract class Contextual {
  final FVMContext _context;

  Contextual(this._context);

  /// Gets context, if no context is passed will get from scope
  @protected
  FVMContext get context => _context;

  @protected
  ServicesProvider get services => _context.services;
  @protected
  Logger get logger => _context.logger;
}

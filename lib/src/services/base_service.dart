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
  Logger get logger => _context.get();
}

abstract class ContextualService extends Contextual {
  ContextualService(super.context);

  @protected
  ServicesProvider get services => _context.get();
}

import 'package:meta/meta.dart';

import '../utils/context.dart';
import 'logger_service.dart';

abstract class Contextual {
  final FvmContext _context;

  const Contextual(this._context);

  /// Gets context, if no context is passed will get from scope
  @protected
  FvmContext get context => _context;

  @protected
  Logger get logger => _context.get();

  @protected
  T get<T extends Contextual>() => _context.get();
}

abstract class ContextualService extends Contextual {
  const ContextualService(super.context);
}

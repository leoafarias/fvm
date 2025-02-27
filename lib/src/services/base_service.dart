import 'package:meta/meta.dart';

import '../utils/context.dart';
import 'logger_service.dart';

abstract class ContextService {
  final FVMContext _context;

  const ContextService(FVMContext context) : _context = context;

  /// Gets context, if no context is passed will get from scope
  @protected
  FVMContext get context => _context;

  Logger get logger => context.logger;
}

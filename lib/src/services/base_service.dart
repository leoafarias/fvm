import 'package:fvm/src/utils/context.dart';

abstract class ContextService {
  final FVMContext? _context;
  const ContextService(FVMContext? context) : _context = context;

  /// Gets context, if no context is passed will get from scope
  FVMContext get context {
    if (_context == null) return ctx;
    return _context!;
  }
}

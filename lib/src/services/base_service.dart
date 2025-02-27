import '../utils/context.dart';
import 'logger_service.dart';

abstract class ContextService {
  final FVMContext _context;

  const ContextService(FVMContext context) : _context = context;

  /// Gets context, if no context is passed will get from scope
  FVMContext get context => _context;

  LoggerService get logger => context.loggerService;
}

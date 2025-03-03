import '../services/base_service.dart';

abstract class Workflow extends ContextualService {
  Workflow(super.context);

  T get<T extends Workflow>() {
    return context.get();
  }
}

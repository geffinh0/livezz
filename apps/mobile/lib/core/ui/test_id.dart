import 'package:material_ui/material_ui.dart';

/// Id estável para E2E (Maestro lê `Semantics.identifier` como resource-id no
/// Android) e para leitores de tela não anunciarem nada a mais.
class TestId extends StatelessWidget {
  const TestId(this.id, {required this.child, super.key});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Semantics(identifier: id, container: true, child: child);
}

import 'package:material_ui/material_ui.dart';

import 'core/tenant/tenant_config.g.dart';

void main() {
  runApp(const LivezzApp());
}

class LivezzApp extends StatelessWidget {
  const LivezzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: generatedTenant.appName,
      home: const Scaffold(body: SizedBox.shrink()),
    );
  }
}

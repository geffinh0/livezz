import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/providers.dart';

void main() {
  runApp(ProviderScope(overrides: appOverrides, child: const LivezzApp()));
}

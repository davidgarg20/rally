import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/router.dart';
import 'package:rally/ui/theme.dart';

class RallyApp extends ConsumerWidget {
  const RallyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Rally',
      theme: RallyTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

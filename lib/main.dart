import 'package:chat/core/app_router.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/core/security/crypto_service.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/disappearing_messages/disappearing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final cryptoService = CryptoService();
  await cryptoService.init();

  runApp(
    ProviderScope(
      overrides: [cryptoServiceProvider.overrideWithValue(cryptoService)],
      child: const AppEntry(),
    ),
  );
}

class AppEntry extends ConsumerStatefulWidget {
  const AppEntry({super.key});

  @override
  ConsumerState<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<AppEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(disappearingMessagesServiceProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zero-Knowledge Chat',
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.authWrapper,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

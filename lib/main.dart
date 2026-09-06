import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/db_helper.dart';
import 'core/audio/spot_audio_handler.dart';
import 'features/ui/theme/app_theme.dart';
import 'features/ui/screens/main_shell.dart';
import 'features/ui/screens/manage_folders_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent Status Bar & Navigation Bar Overlay for Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize SQLite Database Helper
  final dbHelper = DbHelper();
  await dbHelper.database;

  // Initialize Background Audio Service
  await initAudioService();

  runApp(
    const ProviderScope(
      child: SpotLocalApp(),
    ),
  );
}

class SpotLocalApp extends StatelessWidget {
  const SpotLocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpotLocal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return SafeArea(
          top: true,
          bottom: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainShell(),
      routes: {
        '/manage_folders': (context) => const ManageFoldersScreen(),
      },
    );
  }
}

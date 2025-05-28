import 'package:closet_organizer/provider/closet_provider.dart';
import 'package:closet_organizer/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: "/Users/yuriyoshida/Desktop/closet_organizer/.env");
    print('Loaded .env file successfully');
  } catch (e) {
    print('Error loading .env file: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClosetProvider()),
      ],
      child: MaterialApp(
        title: 'Closet Organizer',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          primaryColor: const Color(0xFF6B46C1),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6B46C1),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          fontFamily: 'Roboto',
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
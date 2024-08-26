import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:final_year_app/services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print("Firebase initialized successfully");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          return MaterialApp(
            title: 'Shopee',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            debugShowCheckedModeBanner: false, // Remove the debug banner
            // Conditional routing based on authentication status
            home: authService.user == null ? LoginScreen() : HomeScreen(),
            routes: {
              '/register': (context) => RegisterScreen(),
              '/login': (context) => LoginScreen(),
              '/home': (context) => HomeScreen(),
              '/list': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
                if (args != null && args.containsKey('listId')) {
                  return ListScreen(listId: args['listId']!);
                } else {
                  return ErrorScreen(message: 'List ID is missing'); // Handle missing arguments gracefully
                }
              },
            },
          );
        },
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;

  ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Error'),
      ),
      body: Center(
        child: Text(message, style: TextStyle(fontSize: 18, color: Colors.red)),
      ),
    );
  }
}

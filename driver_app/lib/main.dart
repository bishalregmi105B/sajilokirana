import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'theme/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/driver_provider.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/home_screen.dart';
import 'screens/active_delivery_screen.dart';
import 'screens/earnings_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFFFFFF),
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          return MaterialApp(
            title: appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            initialRoute: auth.isAuthenticated ? '/home' : '/',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(builder: (_) => const LoginScreen());
                case '/otp':
                  final phone = settings.arguments as String;
                  return MaterialPageRoute(builder: (_) => OtpScreen(phone: phone));
                case '/home':
                  return MaterialPageRoute(builder: (_) => const HomeScreen());
                case '/delivery':
                  return MaterialPageRoute(builder: (_) => const ActiveDeliveryScreen());
                case '/earnings':
                  return MaterialPageRoute(builder: (_) => const EarningsScreen());
                case '/history':
                  return MaterialPageRoute(builder: (_) => const HistoryScreen());
                default:
                  return MaterialPageRoute(builder: (_) => const LoginScreen());
              }
            },
          );
        },
      ),
    );
  }
}

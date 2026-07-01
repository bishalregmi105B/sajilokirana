import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'theme/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/shop_provider.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/home_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/reliability_screen.dart';
import 'screens/payouts_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFFFFFF),
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ShopkeeperApp());
}

class ShopkeeperApp extends StatelessWidget {
  const ShopkeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
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
                  return MaterialPageRoute(builder: (_) => const ShopHomeScreen());
                case '/orders':
                  return MaterialPageRoute(builder: (_) => const OrdersScreen());
                case '/inventory':
                  return MaterialPageRoute(builder: (_) => const InventoryScreen());
                case '/reliability':
                  return MaterialPageRoute(builder: (_) => const ReliabilityScreen());
                case '/payouts':
                  return MaterialPageRoute(builder: (_) => const PayoutsScreen());
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

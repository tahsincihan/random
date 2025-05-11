import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'login_screen.dart';
import 'home.dart';

int kTestMode = 0;
String kLiveDomain = "https://mapyourevent.co.uk";
String kTestDomain = "https://mapyourevent.myeenterprises.co.uk";
String kCurrentDomain = kLiveDomain;
int kClientId =  2;
String kClientSecret =  "BO3GPnrJ03iUrVg8piaPbXw5cGGMfSAmmMFT47p1";


void flipEnvironment() {
kTestMode = (kTestMode == 0) ? 1 : 0;

kCurrentDomain = (kTestMode == 0) ? kLiveDomain : kTestDomain;
kClientId = (kTestMode == 0) ? 2 : 2;
kClientSecret = (kTestMode == 0) ? "BO3GPnrJ03iUrVg8piaPbXw5cGGMfSAmmMFT47p1" : "qooYBzdaTJ4AFllFd1KNPFeiWsku7ns1QGvXx5RX";
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('secureBox');

  final box = Hive.box('secureBox');
  final token = box.get('access_token');
  final loginTimeStr = box.get('login_time');

  String initialRoute = '/login';
  if (token != null && loginTimeStr != null) {
    try {
      final loginTime = DateTime.parse(loginTimeStr);
      final oneYearFromLogin = loginTime.add(const Duration(days: 365));
      if (DateTime.now().isBefore(oneYearFromLogin)) {
        initialRoute = '/scanner';
      }
    } catch (_) {}
  }

  runApp(
    ProviderScope(
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MYETicket Scanning',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/scanner': (context) => const QrScanScreen(),
      },
    );
  }
}
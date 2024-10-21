import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:installment_app/adminside/adminpanel.dart';
import 'package:installment_app/clintfront.dart';
import 'package:installment_app/register_page.dart';
import 'firebase_options.dart';
import 'Installmentpages/installment_orderlist.dart';
import 'loginpage.dart';
import 'orderslist.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env");
  //
  // Stripe.publishableKey = dotenv.env["STRIPE_PUBLISH_KEY"]!;
  // await Stripe.instance.applySettings();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/register': (context) => RegisterPage(), // Add your RegisterPage route
        '/login': (context) => LoginPage(), // Add your RegisterPage route
        '/admin': (context) => Admin(), // Add your RegisterPage route
        '/ordersListPage': (context) => CustomerOrdersPage(comingFromCheckoutPage: true,), // Add your RegisterPage route
        '/installmentordersListPage': (context) => InstallmentOrdersPage(comingFromInstallmentPage: true,), // Add your RegisterPage route

      },
      debugShowCheckedModeBanner: false,
      home: FrontPage(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'pages/home_page.dart';
import 'pages/opening_page.dart';
import 'pages/child_login_page.dart';
import 'services/user_state_service.dart';

void main() async {
  await initHiveForFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(FluttermojiController());

    return GraphQLProvider(
      client: ValueNotifier(
        GraphQLClient(
          link: HttpLink('http://localhost:3000/graphql'),
          cache: GraphQLCache(),
        ),
      ),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Character',
        theme: ThemeData(primarySwatch: Colors.red),

        // 👇 Step 1: Start with the OpeningPage as your initial screen
        home: const OpeningPage(),

        // 👇 Step 2: Define your routes so we can navigate after animation
        getPages: [
          GetPage(name: '/', page: () => const OpeningPage()),
          GetPage(name: '/loginWrapper', page: () => const LoginWrapper()),
          GetPage(name: '/home', page: () => const HomePage()),
        ],
      ),
    );
  }
}

class LoginWrapper extends StatefulWidget {
  const LoginWrapper({super.key});

  @override
  State<LoginWrapper> createState() => _LoginWrapperState();
}

class _LoginWrapperState extends State<LoginWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await UserStateService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _isLoggedIn ? const HomePage() : const ChildLoginPage();
  }
}

class AvatarPage extends StatelessWidget {
  const AvatarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Character'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FluttermojiCircleAvatar(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: FluttermojiCustomizer()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FluttermojiSaveWidget(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/stock_sync_provider.dart';
import 'providers/orders_sync_provider.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/firebase_service.dart';
import 'services/socket_service.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_menu_screen.dart';
import 'screens/admin_banners_screen.dart';
import 'screens/admin_products_screen.dart';
import 'screens/admin_sales_screen.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/orders_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // ignore: avoid_print
    print('⚠️  Aviso: Não foi possível carregar .env. Usando valores padrão.');
  }

  try {
    await FirebaseService.initialize();
  } catch (e) {
    // ignore: avoid_print
    print('⚠️  Aviso: Firebase não inicializado. Continuando sem Firebase.');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late AuthProvider _authProvider;
  late AdminProvider _adminProvider;
  late FavoritesProvider _favoritesProvider;
  late ApiService _apiService;
  late SocketService _socketService;
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeProviders();
    // Remover a chamada de _handleIncomingLinks aqui
    // O Flutter está tentando processar /admin como rota inicial, causando erro
  }

  Future<void> _initializeProviders() async {
    final storageService = StorageService();
    _apiService = ApiService();

    _authProvider = AuthProvider(
      apiService: _apiService,
      storageService: storageService,
    );

    _adminProvider = AdminProvider(apiService: _apiService);
    _favoritesProvider = FavoritesProvider(apiService: _apiService);

    await _authProvider.init();

    // Inicializar Socket.io para real-time updates
    _socketService = SocketService();
    final backendUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
    await _socketService.initialize(backendUrl);
  }

  // ignore: unused_element
  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'lejdoces' && uri.path == '/reset-password') {
      navigatorKey.currentState?.pushNamed('/reset-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostrar loading enquanto inicializa.
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateInitialRoutes: (_) => [
              MaterialPageRoute(
                builder: (_) => const _LoadingScreen(),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Erro ao inicializar aplicação'),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return MultiProvider(
          providers: [
            Provider<ApiService>.value(value: _apiService),
            ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: _adminProvider),
            ChangeNotifierProvider<FavoritesProvider>.value(value: _favoritesProvider),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrdersProvider(apiService: _apiService)),
            ChangeNotifierProvider(create: (_) => StockSyncProvider()),
            ChangeNotifierProvider(create: (_) => OrdersSyncProvider()),
            ChangeNotifierProvider<SocketService>.value(value: _socketService),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'L&J Doces e Salgados',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt', 'BR'),
              Locale('en', 'US'),
            ],
            locale: const Locale('pt', 'BR'),
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                // Mostrar splash screen enquanto carrega
                if (authProvider.isLoading) {
                  // Substituído pela tela de carregamento simples
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // O aplicativo sempre iniciará na HomeScreen agora
                return const HomeScreen();
              },
            ),
            routes: {
              '/signin': (context) => const SignInScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/reset-password': (context) => const ResetPasswordScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/checkout': (context) => const CheckoutScreen(),
              '/orders': (context) => const OrdersScreen(),
              '/admin': (context) => const AdminMenuScreen(),
              '/admin/banners': (context) => const AdminBannersScreen(),
              '/admin/products': (context) => const AdminProductsScreen(),
              '/admin/orders': (context) => const AdminOrdersScreen(),
              '/admin/sales': (context) => const AdminSalesScreen(),
              '/admin/analytics': (context) => const AnalyticsScreen(),
            },
            onGenerateRoute: (settings) {
              final routeName = settings.name;

              if (routeName == null || routeName.isEmpty) {
                return MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                );
              }

              final uri = Uri.tryParse(routeName);
              if (uri != null && uri.scheme == 'lejdoces' && uri.path == '/reset-password') {
                return MaterialPageRoute(
                  builder: (context) => const ResetPasswordScreen(),
                );
              }

              switch (routeName) {
                case '/checkout':
                  return MaterialPageRoute(
                    builder: (context) => const CheckoutScreen(),
                  );
                case '/signin':
                  return MaterialPageRoute(
                    builder: (context) => const SignInScreen(),
                  );
                case '/signup':
                  return MaterialPageRoute(
                    builder: (context) => const SignUpScreen(),
                  );
                case '/reset-password':
                  return MaterialPageRoute(
                    builder: (context) => const ResetPasswordScreen(),
                  );
                case '/home':
                  return MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  );
                case '/profile':
                  return MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  );
                case '/orders':
                  return MaterialPageRoute(
                    builder: (context) => const OrdersScreen(),
                  );
                case '/admin':
                  return MaterialPageRoute(
                    builder: (context) => const AdminMenuScreen(),
                  );
                case '/admin/banners':
                  return MaterialPageRoute(
                    builder: (context) => const AdminBannersScreen(),
                  );
                case '/admin/products':
                  return MaterialPageRoute(
                    builder: (context) => const AdminProductsScreen(),
                  );
                case '/admin/orders':
                  return MaterialPageRoute(
                    builder: (context) => const AdminOrdersScreen(),
                  );
                case '/admin/sales':
                  return MaterialPageRoute(
                    builder: (context) => const AdminSalesScreen(),
                  );
                case '/admin/analytics':
                  return MaterialPageRoute(
                    builder: (context) => const AnalyticsScreen(),
                  );
              }

              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              );
            },
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              );
            },
          ),
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

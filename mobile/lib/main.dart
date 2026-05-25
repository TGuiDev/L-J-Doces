import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'models/product_model.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/orders_sync_provider.dart';
import 'providers/stock_sync_provider.dart';
import 'screens/admin_banners_screen.dart';
import 'screens/admin_menu_screen.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/admin_products_screen.dart';
import 'screens/admin_sales_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/product_deep_link_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'services/firebase_service.dart';
import 'services/socket_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Aviso: Nao foi possivel carregar .env. Usando valores padrao.');
  }

  try {
    await FirebaseService.initialize();
  } catch (e) {
    print('Aviso: Firebase nao inicializado. Continuando sem Firebase.');
  }

  if (kIsWeb) {
    usePathUrlStrategy();
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

  late final ApiService _apiService;
  late final AuthProvider _authProvider;
  late final AdminProvider _adminProvider;
  late final FavoritesProvider _favoritesProvider;
  late final SocketService _socketService;
  late final Future<void> _initializationFuture;
  List<Product> _initialTopOrderedProducts = [];

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  ResetPasswordLinkData? _pendingResetLinkData;

  @override
  void initState() {
    super.initState();

    final storageService = StorageService();
    _apiService = ApiService();
    _authProvider = AuthProvider(
      apiService: _apiService,
      storageService: storageService,
    );
    _adminProvider = AdminProvider(apiService: _apiService);
    _favoritesProvider = FavoritesProvider(apiService: _apiService);
    _socketService = SocketService();

    _initializationFuture = _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    await _authProvider.init();

    final backendUrl = dotenv.env['API_BASE_URL'] ?? ApiService.defaultBaseUrl;
    await Future.wait<void>([
      _socketService.initialize(backendUrl),
      _preloadHomeData(),
    ]);
    await _initializeDeepLinks();
  }

  Future<void> _preloadHomeData() async {
    final preloadTasks = <Future<void>>[
      _adminProvider.fetchCategories(),
      _adminProvider.fetchProductsPage(
        refresh: true,
        forceApiRefresh: true,
      ),
      _loadInitialTopOrderedProducts(),
    ];

    final token = _authProvider.token;
    if (_authProvider.isAuthenticated && token != null) {
      preloadTasks.add(_favoritesProvider.fetchFavorites(token));
    }

    await Future.wait<void>(preloadTasks);
  }

  Future<void> _loadInitialTopOrderedProducts() async {
    try {
      _initialTopOrderedProducts = await _apiService.getTopOrderedProducts();
    } catch (e) {
      print('Aviso: nao foi possivel pre-carregar mais pedidos: $e');
      _initialTopOrderedProducts = [];
    }
  }

  Future<void> _initializeDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDeepLink(initialUri);
        });
      }
    } catch (e) {
      print('Aviso: nao foi possivel ler link inicial: $e');
    }

    _linkSubscription = _appLinks!.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        print('Aviso: erro ao receber deep link: $error');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    if (_isResetPasswordUri(uri)) {
      _openResetPassword(_parseResetPasswordLink(uri));
    }
  }

  void _openResetPassword(ResetPasswordLinkData linkData) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingResetLinkData = linkData;
      return;
    }

    navigator.pushNamed(
      '/reset-password',
      arguments: linkData,
    );
  }

  void _flushPendingResetLink() {
    final linkData = _pendingResetLinkData;
    if (linkData == null || navigatorKey.currentState == null) return;

    _pendingResetLinkData = null;
    _openResetPassword(linkData);
  }

  bool _isResetPasswordUri(Uri uri) {
    if (uri.scheme == 'lejdoces') {
      return uri.host == 'reset-password' || uri.path == '/reset-password';
    }

    return uri.path == '/reset-password';
  }

  ResetPasswordLinkData _parseResetPasswordLink(Uri uri) {
    final params = <String, String>{...uri.queryParameters};

    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      final fragmentQuery = fragment.contains('?')
          ? fragment.substring(fragment.indexOf('?') + 1)
          : fragment;

      params.addAll(Uri.splitQueryString(fragmentQuery));
    }

    return ResetPasswordLinkData(
      code: params['code'],
      accessToken: params['access_token'],
      refreshToken: params['refresh_token'],
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: _apiService),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<AdminProvider>.value(value: _adminProvider),
        ChangeNotifierProvider<FavoritesProvider>.value(
          value: _favoritesProvider,
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => OrdersProvider(apiService: _apiService),
        ),
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
        builder: _buildWebPhoneFrame,
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
        home: FutureBuilder<void>(
          future: _initializationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SplashScreen();
            }

            if (snapshot.hasError) {
              return _InitializationErrorScreen(error: snapshot.error);
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _flushPendingResetLink();
            });

            return HomeScreen(
              initialTopOrderedProducts: _initialTopOrderedProducts,
            );
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
        onGenerateRoute: _onGenerateRoute,
        onUnknownRoute: (_) {
          return MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          );
        },
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;

    if (routeName == null || routeName.isEmpty) {
      return MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      );
    }

    final uri = Uri.tryParse(routeName);
    if (uri != null && _isResetPasswordUri(uri)) {
      return MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(
          linkData: _parseResetPasswordLink(uri),
        ),
        settings: settings,
      );
    }

    if (uri != null &&
        uri.pathSegments.length == 2 &&
        (uri.pathSegments.first == 'produto' ||
            uri.pathSegments.first == 'product')) {
      return MaterialPageRoute(
        builder: (context) => ProductDeepLinkScreen(
          productId: uri.pathSegments[1],
        ),
        settings: settings,
      );
    }

    return null;
  }

  Widget _buildWebPhoneFrame(BuildContext context, Widget? child) {
    if (!kIsWeb || child == null) {
      return child ?? const SizedBox.shrink();
    }

    const phoneAspectRatio = 9 / 17;
    const maxPhoneWidth = 600.0;
    const borderWidth = 0.1;
    const pagePadding = 0.1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = MediaQuery.of(context).size;
        final availableWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : viewport.width;
        final availableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : viewport.height;

        final maxContentWidth =
            (availableWidth - (pagePadding * 2) - (borderWidth * 2))
                .clamp(280.0, maxPhoneWidth);
        final maxContentHeight =
            availableHeight - (pagePadding * 2) - (borderWidth * 2);

        var phoneWidth = maxContentWidth;
        var phoneHeight = phoneWidth / phoneAspectRatio;

        if (phoneHeight > maxContentHeight) {
          phoneHeight = maxContentHeight.clamp(0.0, double.infinity);
          phoneWidth = phoneHeight * phoneAspectRatio;
        }

        final phoneSize = Size(phoneWidth, phoneHeight);

        return ColoredBox(
          color: Colors.black,
          child: Center(
            child: Container(
              width: phoneWidth + (borderWidth * 2),
              height: phoneHeight + (borderWidth * 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(36),
              ),
              padding: const EdgeInsets.all(borderWidth),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(size: phoneSize),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InitializationErrorScreen extends StatelessWidget {
  final Object? error;

  const _InitializationErrorScreen({
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Erro ao inicializar aplicacao'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'models/expense.dart';
import 'models/trip.dart';
import 'models/category.dart';
import 'providers/expense_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/category_provider.dart';
import 'screens/daily_expenses_page.dart';
import 'screens/trip_expenses_page.dart';
import 'screens/settings_page.dart';
import 'widgets/expense_dialog.dart';
import 'widgets/trip_dialog.dart';

// Global navigator key for accessing context from providers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // Register Hive adapters
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(TripAdapter());
  Hive.registerAdapter(CategoryAdapter());

  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Trip>('trips');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripProvider()..init()),
        ChangeNotifierProxyProvider<TripProvider, ExpenseProvider>(
          create:
              (context) =>
                  ExpenseProvider(context.read<TripProvider>())..init(),
          update:
              (context, tripProvider, previous) =>
                  previous ?? ExpenseProvider(tripProvider)
                    ..init(),
        ),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..init()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'SplitZilla',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
            primary: Colors.blue.shade400,
            secondary: Colors.tealAccent.shade400,
            surface: const Color(0xFF1A1A1A),
            onSurface: Colors.white,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        ),
        home: const HomePage(),
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_splitzilla.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 8),
            const Text('SplitZilla'),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_splitzilla.png',
                    height: 48,
                    width: 48,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'SplitZilla',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'SplitZilla',
                  applicationVersion: '1.0.0',
                  applicationIcon: const FlutterLogo(size: 48),
                  children: const [
                    Text(
                      'SplitZilla is a feature-rich expense tracker app that helps you manage your personal and group expenses.',
                    ),
                    SizedBox(height: 16),
                    Text('Created with ❤️ using Flutter'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [DailyExpensesPage(), TripExpensesPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Daily',
          ),
          NavigationDestination(icon: Icon(Icons.card_travel), label: 'Trips'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () {
          if (_selectedIndex == 0) {
            showDialog(
              context: context,
              builder: (context) => const ExpenseDialog(),
            );
          } else {
            showDialog(
              context: context,
              builder: (context) => const TripDialog(),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

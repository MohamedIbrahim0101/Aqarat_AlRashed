import 'package:flutter/widgets.dart' as fw;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/PropertyService.dart';
import 'package:my_app/models/dashboard_service.dart';
import 'package:my_app/widgets/PropertiesManageScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ تم إضافة المكتبة

// **********************************************
// 1. الثوابت والألوان
// **********************************************
const Color primaryBlue = Color(0xFF142B49);
const Color cardShadowColor = Color(0xFFE0E0E0);
const Color backgroundColor = Color(0xFFF7F7F7);
const double maxContentWidth = 1200.0;

// **********************************************
// 2. تهيئة Supabase (من .env)
// **********************************************
late final SupabaseClient supabase;
late final DashboardService dashboardService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تحميل ملف .env
  await dotenv.load(fileName: ".env");

  // ✅ قراءة القيم من .env
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;

  supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
final dashboardService = DashboardService();

  runApp(const Dashboardscreen());
}

class Dashboardscreen extends fw.StatefulWidget {
  const Dashboardscreen({super.key});

  @override
  fw.State<Dashboardscreen> createState() => _MyAppState();
}

class _MyAppState extends fw.State<Dashboardscreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return Directionality(
          textDirection: fw.TextDirection.ltr,
          child: child!,
        );
      },
      theme: ThemeData(fontFamily: 'Cairo', useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(service: dashboardService),
    );
  }
}

// ------------------------------------------------------------------
// 3. الشاشة الرئيسية (DashboardScreen)
// ------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  final DashboardService service;
  const DashboardScreen({required this.service, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  PropertyItem? _selectedProperty;
  bool _isLoadingStats = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingStats = true;
      _errorMessage = null;
    });

    try {
      final stats = await widget.service.fetchDashboardStats();
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingStats = false;
      });
      print('Error loading dashboard stats: $_errorMessage');
    }
  }

  void _onPropertySelected(PropertyItem? property) {
    setState(() {
      _selectedProperty = property;
      print('Selected property: ${property?.name ?? 'All Properties'}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          const CustomAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth),
                  child: _isLoadingStats
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Text(
                                'Error loading data: $_errorMessage',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : StatCardsGrid(
                              stats: _stats!,
                              service: widget.service,
                              selectedProperty: _selectedProperty,
                              onPropertySelected: _onPropertySelected,
                            ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// 4. CustomAppBar
// ------------------------------------------------------------------
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      color: primaryBlue,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildLogo(),
                      const SizedBox(width: 30),
                      const Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _NavLinksRow(),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNotificationButton(),
                    const SizedBox(width: 15),
                    _buildLogoutButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.apartment, color: Colors.white, size: 24),
        SizedBox(width: 8),
        Text(
          'عقارات مشعل الراشد',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return const Stack(
      children: [
        Icon(Icons.notifications_none, color: Colors.white, size: 24),
        Positioned(
          right: 0,
          top: 0,
          child: CircleAvatar(
            radius: 6,
            backgroundColor: Colors.red,
            child: Text(
              '3',
              style: TextStyle(color: Colors.white, fontSize: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Logout', style: TextStyle(fontSize: 14)),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        minimumSize: Size.zero,
      ),
    );
  }
}

// ------------------------------------------------------------------
// 5. _NavLinksRow
// ------------------------------------------------------------------
class _NavLinksRow extends StatelessWidget {
  const _NavLinksRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        NavLink(title: 'Dashboard', isSelected: true),
        NavDropdownLink(
          title: 'Properties & Units',
          icon: Icons.home,
          menuItems: [
            {'title': 'Properties Manage', 'icon': Icons.list},
            {'title': 'Properties Add', 'icon': Icons.add_circle_outline},
            {'title': 'Units Manage', 'icon': Icons.list},
            {'title': 'Units Add', 'icon': Icons.add_circle_outline},
          ],
        ),
        NavDropdownLink(
          title: 'Contracts',
          icon: Icons.description,
          menuItems: [
            {'title': 'Contracts Manage', 'icon': Icons.list},
            {'title': 'Contracts Add', 'icon': Icons.add_circle_outline},
            {'title': 'Contracts Report', 'icon': Icons.bar_chart},
            {'title': 'Rents Report', 'icon': Icons.description_sharp},
          ],
        ),
        NavDropdownLink(
          title: 'Payments',
          icon: Icons.attach_money,
          menuItems: [
            {'title': 'Add Payment', 'icon': Icons.add_circle_outline},
            {'title': 'Rents', 'icon': Icons.receipt_long},
            {'title': 'Due Rents', 'icon': Icons.warning_amber},
            {'title': 'Payment History', 'icon': Icons.history},
            {'title': 'Incomes Manage', 'icon': Icons.list},
            {'title': 'Incomes Add', 'icon': Icons.add_circle_outline},
          ],
        ),
        NavDropdownLink(
          title: 'People',
          icon: Icons.person,
          menuItems: [
            {'title': 'Owners', 'icon': Icons.person},
            {'title': 'Customers', 'icon': Icons.group},
          ],
        ),
        SizedBox(width: 20),
      ],
    );
  }
}

// ✅ باقي الكود (NavLink, NavDropdownLink, StatCardsGrid, StatCard) 
// كما هو بالضبط بدون أي تعديل.


// ------------------------------------------------------------------
// 6. NavLink
// ------------------------------------------------------------------
class NavLink extends StatelessWidget {
  final String title;
  final bool isSelected;
  final IconData? icon;

  const NavLink({
    required this.title,
    this.isSelected = false,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        children: [
          if (icon != null)
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 20,
            ),
          if (icon != null) const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// 7. NavDropdownLink
// ------------------------------------------------------------------
class NavDropdownLink extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Map<String, dynamic>> menuItems;

  const NavDropdownLink({
    required this.title,
    required this.menuItems,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    List<PopupMenuEntry<String>> items = [];

    for (int i = 0; i < menuItems.length; i++) {
      final item = menuItems[i];

      if (title == 'Properties & Units' && i == 2 && menuItems.length > 2) {
        items.add(const PopupMenuDivider());
      } else if (title == 'Contracts' && i == 2 && menuItems.length > 2) {
        items.add(const PopupMenuDivider());
      } else if (title == 'Payments' && i == 4 && menuItems.length > 4) {
        items.add(const PopupMenuDivider());
      }

      items.add(
        PopupMenuItem<String>(
          value: item['title'] as String,
          padding: EdgeInsets.zero,
          child: Container(
            width: 250,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData? ?? Icons.error,
                  color: Colors.black54,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  item['title'] as String,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: '',
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) => items,
      onSelected: (value) {
        print('Selected: $value');
        if (value == 'Properties Manage') {
          Navigator.of(context).push(
            MaterialPageRoute(
builder: (context) => PropertiesManageScreen(service: PropertyService()),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, color: Colors.white70, size: 20),
            if (icon != null) const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// 8. StatCardsGrid
// ------------------------------------------------------------------
class StatCardsGrid extends StatelessWidget {
  final DashboardStats stats;
  final DashboardService service;
  final PropertyItem? selectedProperty;
  final ValueChanged<PropertyItem?> onPropertySelected;

  const StatCardsGrid({
    required this.stats,
    required this.service,
    required this.selectedProperty,
    required this.onPropertySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'ar',
      symbol: ' د.ك',
      decimalDigits: 3,
    );

    final List<Map<String, dynamic>> statItems = [
      {
        'title': 'Properties',
        'value': stats.propertiesCount.toString(),
        'isDropdown': true,
      },
      {'title': 'Units', 'value': stats.unitsCount.toString()},
      {'title': 'Owners', 'value': stats.ownersCount.toString()},
      {'title': 'Customers', 'value': stats.customersCount.toString()},
      {
        'title': 'Cash Inflows',
        'value': currencyFormatter.format(stats.cashInflows),
      },
      {
        'title': 'Cash Outflows',
        'value': currencyFormatter.format(stats.cashOutflows),
      },
      {
        'title': 'Net Income',
        'value': currencyFormatter.format(stats.netIncome),
      },
      {'title': 'Due Rents', 'value': stats.dueRentsCount.toString()},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20.0,
            mainAxisSpacing: 20.0,
            childAspectRatio: crossAxisCount == 2 ? 3.8 : 5.0,
          ),
          itemCount: statItems.length,
          itemBuilder: (context, index) {
            final stat = statItems[index];
            return StatCard(
              title: stat['title'] as String,
              value: stat['value'] as String,
              isDropdown: stat['isDropdown'] as bool? ?? false,
              service: service,
              selectedProperty: selectedProperty,
              onPropertySelected: onPropertySelected,
            );
          },
        );
      },
    );
  }
}

// ------------------------------------------------------------------
// 9. StatCard
// ------------------------------------------------------------------
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isDropdown;
  final DashboardService? service;
  final PropertyItem? selectedProperty;
  final ValueChanged<PropertyItem?>? onPropertySelected;

  const StatCard({
    required this.title,
    required this.value,
    this.isDropdown = false,
    this.service,
    this.selectedProperty,
    this.onPropertySelected,
    super.key,
  });

  Widget _buildTitle(BuildContext context) {
    if (!isDropdown) {
      return Text(
        title,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          fontWeight: FontWeight.normal,
        ),
      );
    }

    if (service == null || onPropertySelected == null) {
      return const Text(
        'Properties (Error)',
        style: TextStyle(color: Colors.red),
      );
    }

    return FutureBuilder<List<PropertyItem>>(
      future: service!.fetchPropertiesList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Wrap(
            spacing: 5.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Properties',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Wrap(
            spacing: 5.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Properties',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.black87, size: 18),
            ],
          );
        }

        final properties = snapshot.data!;
        final displayTitle = selectedProperty?.name ?? 'Properties';

        List<PopupMenuEntry<PropertyItem?>> items = [
          const PopupMenuItem<PropertyItem?>(
            value: null,
            child: Text(
              'View All Properties',
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue),
            ),
          ),
          const PopupMenuDivider(),
          ...properties.map(
            (prop) => PopupMenuItem<PropertyItem?>(
              value: prop,
              child: Text(prop.name),
            ),
          ),
        ];

        return PopupMenuButton<PropertyItem?>(
          tooltip: '',
          offset: const Offset(0, 40),
          onSelected: onPropertySelected,
          itemBuilder: (context) => items,
          child: Wrap(
            spacing: 5.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                displayTitle,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: Colors.black87,
                size: 18,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2.0,
      shadowColor: cardShadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(context),
            const SizedBox(height: 10),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

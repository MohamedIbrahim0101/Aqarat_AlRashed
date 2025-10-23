// File: lib/widgets/dashboardScreen.dart (Revised English Version)

import 'package:flutter/widgets.dart' as fw;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/main.dart';
import 'package:my_app/services/contracts_manage_service.dart'
    show ContractService;
import 'package:my_app/services/dashboard_service.dart';
import 'package:my_app/services/PropertyService.dart';
import 'package:my_app/widgets/AddPropertyScreen.dart';
import 'package:my_app/widgets/PropertiesManageScreen.dart'
    show PropertiesManageScreen;
import 'package:my_app/widgets/add%20_new_payment.dart';
import 'package:my_app/widgets/contracts_manage_screen.dart';
import 'package:my_app/widgets/contracts_report.dart';
import 'package:my_app/widgets/customers.dart';
import 'package:my_app/widgets/notificatios.dart';
import 'package:my_app/widgets/owners_screen.dart';
import 'package:my_app/widgets/payment_history.dart'
    hide
        PropertyService,
        ContractService,
        PropertiesManageScreen,
        AddPropertyScreen,
        ContractsManageScreen,
        AddNewContractScreen,
        ContractsReportPage,
        AddPaymentScreen;
import 'package:my_app/widgets/rent_due.dart';
import 'package:my_app/widgets/rent_management.dart';
import 'package:my_app/widgets/rent_screen.dart'
    hide PropertyService, ContractService;
import 'package:my_app/widgets/unit_manage_screen.dart';
import 'package:my_app/widgets/units_add.dart';
import 'package:my_app/widgets/add_new_contract_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


// ------------------------------------------------------------------
// 1. Constants and Colors
// ------------------------------------------------------------------
const Color primaryBlue = Color(0xFF142B49);
const Color cardShadowColor = Color(0xFFE0E0E0);
const Color backgroundColor = Color(0xFFF7F7F7);
const double maxContentWidth = 1200.0;

// ------------------------------------------------------------------
// 2. Dashboardscreen (Root Widget)
// ------------------------------------------------------------------
class Dashboardscreen extends fw.StatefulWidget {
    final DashboardService dashboardService;
    final PropertyService propertyService;
    final ContractService contractService;

    const Dashboardscreen({
        required this.dashboardService,
        required this.propertyService,
        required this.contractService,
        super.key,
    });

    @override
    fw.State<Dashboardscreen> createState() => _MyAppState();
}

class _MyAppState extends fw.State<Dashboardscreen> {
    @override
    Widget build(BuildContext context) {
        return Directionality(
            // تحديد الاتجاه من اليمين لليسار (RTL) لدعم اللغة العربية
            textDirection: fw.TextDirection.rtl,
            child: DashboardScreen(
                service: widget.dashboardService,
                propertyService: widget.propertyService,
                contractService: widget.contractService,
            ),
        );
    }
}

// ------------------------------------------------------------------
// 3. DashboardScreen (تم تعديل هذه الدالة)
// ------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
    final DashboardService service;
    final PropertyService propertyService;
    final ContractService contractService;

    const DashboardScreen({
        required this.service,
        required this.propertyService,
        required this.contractService,
        super.key,
    });

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
                    // شريط التنقل العلوي (بدون الروابط الآن)
                    CustomAppBar(
                        propertyService: widget.propertyService,
                        contractService: widget.contractService,
                    ),
                    
                    // ------------------------------------------------------------------
                    // ✅ FIX: تم نقل شريط الروابط إلى جسم الصفحة هنا
                    // ------------------------------------------------------------------
                    Container(
                        color: Colors.white, // خلفية بيضاء لشريط الروابط الجديد
                        child: Center(
                            child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                                    child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: _NavLinksRow(
                                            propertyService: widget.propertyService,
                                            contractService: widget.contractService,
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                    // ------------------------------------------------------------------
                    
                    // محتوى لوحة التحكم (مؤشرات الأداء)
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
                                                    textDirection: fw.TextDirection.ltr,
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
// 4. CustomAppBar (تم تعديل هذه الدالة)
// ------------------------------------------------------------------
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
    final PropertyService propertyService;
    final ContractService contractService;

    const CustomAppBar({
        required this.propertyService,
        required this.contractService,
        super.key,
    });

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
                                // 1. قسم الشعار واسم الشركة (Flexible لضمان عدم الفيضان)
                                Flexible(
                                    flex: 1,
                                    child: _buildLogo(),
                                ),

                                // 2. تم حذف روابط التنقل من هنا

                                // 3. قسم الإشعارات وتسجيل الخروج (يجب أن يكونا أصغر ما يمكن)
                                Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        const SizedBox(width: 20), // فاصل بين الشعار والأزرار
                                        _buildNotificationButton(context),
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
        return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                const Icon(Icons.apartment, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                // النص نفسه يجب أن يكون مرناً أيضاً لضمان الاقتصاص
                Flexible(
                    child: const Text(
                        'Mishaal Al-Rashed Real Estate',
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis, 
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                        ),
                    ),
                ),
            ],
        );
    }

    Widget _buildNotificationButton(BuildContext context) {
        return GestureDetector(
            onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ContractsNotificationPage(),
                    ),
                );
            },
            child: Stack(
                children: [
                    const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                    Positioned(
                        left: 0,
                        top: 0,
                        child: CircleAvatar(
                            radius: 6,
                            backgroundColor: Colors.red,
                            child: Text(
                                '3', // هنا ممكن تربطه بعدد الإشعارات الجديدة
                                style: const TextStyle(color: Colors.white, fontSize: 8),
                            ),
                        ),
                    ),
                ],
            ),
        );
    }

    Widget _buildLogoutButton() {
        return ElevatedButton.icon(
            onPressed: () async {
                // تسجيل الخروج من Supabase
                await Supabase.instance.client.auth.signOut();

                // مسح حالة تسجيل الدخول من SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);

                // العودة لشاشة تسجيل الدخول
                navigatorKey.currentState!.pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                );
            },
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
// 5. _NavLinksRow (تم حذف Income/Outflow منها)
// ------------------------------------------------------------------
class _NavLinksRow extends StatelessWidget {
    final PropertyService propertyService;
    final ContractService contractService;

    const _NavLinksRow({
        required this.propertyService,
        required this.contractService,
        super.key,
    });

    void _navigateTo(BuildContext context, String title) {
        if (title == 'Properties Manage') {
            Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) =>
                        PropertiesManageScreen(service: propertyService),
                ),
            );
        } else if (title == 'Properties Add') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddPropertyScreen(service: propertyService),
                ),
            );
        } else if (title == 'Units Manage') {
            Navigator.of(
                context,
            ).push(MaterialPageRoute(builder: (context) => UnitsManageScreen()));
        } else if (title == 'Units Add') {
            Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => AddUnitScreen(
                        controller: UnitController(),
                    ),
                ),
            );
        } else if (title == 'Contracts Manage') {
            Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => ContractsManageScreen(service: contractService),
                ),
            );
        }
        // ✅ Add Contract navigation
        else if (title == 'Contracts Add') {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddNewContractScreen()),
            );
        }
        // ✅ Contracts Report navigation
        else if (title == 'Contracts Report') {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContractsReportPage()),
            );
        }
        // ✅ Rents Report navigation
        else if (title == 'Rents Report') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RentScreen(),
                ),
            );
        } else if (title == 'Add Payment') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const AddPaymentScreen(),
                ),
            );
        } else if (title == 'Rents') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RentManagementScreen(),
                ),
            );
        } else if (title == 'Due Rents') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExpiredRentsReportScreen(),
                ),
            );
        } else if (title == 'Payment History') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PaymentHistoryScreen(),
                ),
            );
        } else if (title == 'Owners') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const OwnersScreen(),
                ),
            );
        } else if (title == 'Customers') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CustomerListPage(),
                ),
            );
        } else if (title == '_buildNotificationButton') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ContractsNotificationPage(),
                ),
            );
        } else {
            print('Navigate to $title');
        }
    }

    @override
    Widget build(BuildContext context) {
        return Row(
            children: [
                const NavLink(title: 'Dashboard', isSelected: true),
                NavDropdownLink(
                    title: 'Properties & Units',
                    icon: Icons.home,
                    menuItems: const [
                        {
                            'title': 'Properties Manage',
                            'label': 'Manage Properties',
                            'icon': Icons.list,
                        },
                        {
                            'title': 'Properties Add',
                            'label': 'Add Property',
                            'icon': Icons.add_circle_outline,
                        },
                        {
                            'title': 'Units Manage',
                            'label': 'Manage Units',
                            'icon': Icons.list,
                        },
                        {
                            'title': 'Units Add',
                            'label': 'Add Unit',
                            'icon': Icons.add_circle_outline,
                        },
                    ],
                    onSelected: (value) => _navigateTo(context, value),
                ),
                NavDropdownLink(
                    title: 'Contracts',
                    icon: Icons.description,
                    menuItems: const [
                        {
                            'title': 'Contracts Manage',
                            'label': 'Manage Contracts',
                            'icon': Icons.list,
                        },
                        {
                            'title': 'Contracts Add',
                            'label': 'Add Contract',
                            'icon': Icons.add_circle_outline,
                        },
                        {
                            'title': 'Contracts Report',
                            'label': 'Contracts Report',
                            'icon': Icons.bar_chart,
                        },
                        {
                            'title': 'Rents Report',
                            'label': 'Rents Report',
                            'icon': Icons.description_sharp,
                        },
                    ],
                    onSelected: (value) => _navigateTo(context, value),
                ),
                NavDropdownLink(
                    title: 'Payments',
                    icon: Icons.attach_money,
                    menuItems: const [
                        {
                            'title': 'Add Payment',
                            'label': 'Add Payment',
                            'icon': Icons.add_circle_outline,
                        },
                        {'title': 'Rents', 'label': 'Rents', 'icon': Icons.receipt_long},
                        {
                            'title': 'Due Rents',
                            'label': 'Due Rents',
                            'icon': Icons.warning_amber,
                        },
                        {
                            'title': 'Payment History',
                            'label': 'Payment History',
                            'icon': Icons.history,
                        },
                    ],
                    onSelected: (value) => _navigateTo(context, value),
                ),
                NavDropdownLink(
                    title: 'People',
                    icon: Icons.person,
                    menuItems: const [
                        {'title': 'Owners', 'label': 'Owners', 'icon': Icons.person},
                        {'title': 'Customers', 'label': 'Customers', 'icon': Icons.group},
                    ],
                    onSelected: (value) => _navigateTo(context, value),
                ),
                // تم حذف SizedBox(width: 20) النهائي هنا لعدم الحاجة إليه بعد التمرير
            ],
        );
    }
}

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
            // تم تقليل التباعد الأفقي قليلاً ليتناسب مع شريط الروابط الجديد
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
                children: [
                    if (icon != null)
                        Icon(
                            icon,
                            color: isSelected ? primaryBlue : Colors.black87, // تغيير لون الروابط
                            size: 20,
                        ),
                    if (icon != null) const SizedBox(width: 4),
                    Text(
                        title,
                        style: TextStyle(
                            color: isSelected ? primaryBlue : Colors.black87, // تغيير لون النص
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
    final ValueChanged<String> onSelected;

    const NavDropdownLink({
        required this.title,
        required this.menuItems,
        required this.onSelected,
        this.icon,
        super.key,
    });

    @override
    Widget build(BuildContext context) {
        List<PopupMenuEntry<String>> items = [];

        for (int i = 0; i < menuItems.length; i++) {
            final item = menuItems[i];
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
                                    item['label'] as String,
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
            onSelected: onSelected,
            child: Padding(
                // تم تقليل التباعد الأفقي قليلاً ليتناسب مع شريط الروابط الجديد
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        if (icon != null) Icon(icon, color: Colors.black87, size: 20),
                        if (icon != null) const SizedBox(width: 4),
                        Text(
                            title,
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.black87, size: 20),
                    ],
                ),
            ),
        );
    }
}

// ------------------------------------------------------------------
// 8. StatCardsGrid (تم حذف Cash Inflows/Outflows/Net Income منها وتعديل تنسيق العملة)
// ------------------------------------------------------------------
// ... (باقي الكود لـ StatCardsGrid و StatCard يبقى كما هو)
// ... (لأنها لا تتعلق بالـ App Bar أو الـ Nav Links)

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

    void handleCardTap(BuildContext context, String title) {
        if (title == 'Properties') {
            Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) =>
                        PropertiesManageScreen(service: PropertyService()),
                ),
            );
        } else if (title == 'Units') {
            Navigator.of(
                context,
            ).push(MaterialPageRoute(builder: (context) => UnitsManageScreen()));
        } else if (title == 'Owners') {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OwnersScreen()),
            );
        } else if (title == 'Customers') {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerListPage()),
            );
        } else if (title == 'Due Rents') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExpiredRentsReportScreen(),
                ),
            );
        }
    }

    @override
    Widget build(BuildContext context) {
        // تنسيق العملة بدون رمز/اسم "ريال"
        final currencyFormatter = NumberFormat.currency(
            locale: 'ar_SA',
            symbol: '', // تم إزالة رمز العملة هنا
            decimalDigits: 2,
        );

        // تم حذف Cash Inflows, Cash Outflows, Net Income
        final List<Map<String, dynamic>> statItems = [
            {
                'title': 'Properties',
                'value': stats.propertiesCount.toString(),
                'isDropdown': true,
            },
            {'title': 'Units', 'value': stats.unitsCount.toString()},
            {'title': 'Owners', 'value': stats.ownersCount.toString()},
            {'title': 'Customers', 'value': stats.customersCount.toString()},
            {'title': 'Due Rents', 'value': stats.dueRentsCount.toString()},
        ];

        return LayoutBuilder(
            builder: (context, constraints) {
                // تحديد عدد الأعمدة بناءً على عرض الشاشة
                final crossAxisCount =
                    constraints.maxWidth >
                        900 // شاشات كبيرة جداً
                        ? 4
                        : constraints.maxWidth >
                                650 // شاشات تابلت/لابتوب
                            ? 2
                            : 1; // شاشات الموبايل

                return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20.0,
                        mainAxisSpacing: 20.0,
                        childAspectRatio: crossAxisCount == 4
                            ? 1.5 // شاشات كبيرة
                            : crossAxisCount == 2
                                ? 2.5 // تابلت
                                : 3.5, // موبايل
                    ),
                    itemCount: statItems.length,
                    itemBuilder: (context, index) {
                        final stat = statItems[index];
                        return GestureDetector(
                            onTap: () => handleCardTap(context, stat['title'] as String),
                            child: StatCard(
                                title: stat['title'] as String,
                                value: stat['value'] as String,
                                isDropdown: stat['isDropdown'] as bool? ?? false,
                                service: service,
                                selectedProperty: selectedProperty,
                                onPropertySelected: onPropertySelected,
                            ),
                        );
                    },
                );
            },
        );
    }
}

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
                style: const TextStyle(fontSize: 12, color: Colors.black87),
            );
        }

        if (service == null || onPropertySelected == null) {
            return Text(
                '$title (Service Error)',
                style: const TextStyle(color: Colors.red),
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
                final displayTitle = selectedProperty?.name ?? title;

                List<PopupMenuEntry<PropertyItem?>> items = [
                    const PopupMenuItem<PropertyItem?>(
                        value: null,
                        child: Text(
                            'Show All Properties',
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
                    tooltip: 'Filter by property',
                    offset: const Offset(0, 40),
                    onSelected: onPropertySelected,
                    itemBuilder: (context) => items,
                    child: Wrap(
                        spacing: 5.0,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                            // ✅ استخدام ConstrainedBox لتجنب الفيض الأفقي في حالة عرض اسم عقار طويل
                            ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.4,
                                ), // تحديد أقصى عرض
                                child: Text(
                                    displayTitle,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
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
                                alignment: Alignment.centerRight,
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
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// *****************************************************************************
// 1. DATA MODEL (Owner)
// *****************************************************************************
class Owner {
  final int id;
  final String name;
  final String? bankAccount;

  Owner({
    required this.id,
    required this.name,
    this.bankAccount,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'] as int,
      name: json['name'] as String,
      bankAccount: json['bank_account'] as String?,
    );
  }
}

// *****************************************************************************
// 2. OWNER SERVICE (Supabase)
// *****************************************************************************
class OwnerService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Owner>> fetchOwners() async {
    try {
      final data = await _client
          .from('owners')
          .select('id, name, bank_account')
          .order('id', ascending: true) as List<dynamic>;
      return data.map((e) => Owner.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('فشل في جلب الملاك: ${e.toString()}');
    }
  }

  Future<void> deleteOwner(int id) async {
    try {
      await _client.from('owners').delete().eq('id', id);
    } catch (e) {
      throw Exception('فشل في حذف المالك: ${e.toString()}');
    }
  }

  Future<void> updateOwner(int id, String newName, String newBankAccount) async {
    try {
      await _client.from('owners').update({
        'name': newName,
        'bank_account': newBankAccount,
      }).eq('id', id);
    } catch (e) {
      throw Exception('فشل في تعديل المالك: ${e.toString()}');
    }
  }

  Future<void> addOwner(String name, String bankAccount) async {
    try {
      await _client.from('owners').insert({
        'name': name,
        'bank_account': bankAccount,
      });
    } catch (e) {
      throw Exception('فشل في إضافة المالك: ${e.toString()}');
    }
  }
}

// *****************************************************************************
// 3. ADD/EDIT OWNER SCREEN
// *****************************************************************************
class AddEditOwnerScreen extends StatefulWidget {
  final Owner? owner;
  final VoidCallback onSaved;

  const AddEditOwnerScreen({super.key, this.owner, required this.onSaved});

  @override
  State<AddEditOwnerScreen> createState() => _AddEditOwnerScreenState();
}

class _AddEditOwnerScreenState extends State<AddEditOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final OwnerService _ownerService = OwnerService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.owner != null) {
      _nameController.text = widget.owner!.name;
      _bankAccountController.text = widget.owner!.bankAccount ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  void _saveOwner() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final name = _nameController.text;
      final bankAccount = _bankAccountController.text;
      final isUpdating = widget.owner != null;

      try {
        if (isUpdating) {
          await _ownerService.updateOwner(widget.owner!.id, name, bankAccount);
        } else {
          await _ownerService.addOwner(name, bankAccount);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUpdating ? 'تم تعديل المالك بنجاح!' : 'تم إضافة المالك بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onSaved();
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = widget.owner != null;
    final title = isUpdating ? 'تعديل بيانات المالك' : 'إضافة مالك جديد';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text(title, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.indigo.shade800,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 7, offset: const Offset(0, 3))],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                        textAlign: TextAlign.center),
                    const Divider(height: 30, thickness: 1),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'الرجاء إدخال اسم المالك' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bankAccountController,
                      decoration: const InputDecoration(
                        labelText: 'الحساب البنكي',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'الرجاء إدخال الحساب البنكي' : null,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveOwner,
                      icon: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Icon(isUpdating ? Icons.save : Icons.add, color: Colors.white),
                      label: Text(_isLoading ? 'جاري الحفظ...' : (isUpdating ? 'حفظ التعديلات' : 'إضافة المالك'),
                          style: const TextStyle(fontSize: 18, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUpdating ? Colors.orange.shade700 : Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// *****************************************************************************
// 4. OWNERS SCREEN
// *****************************************************************************
class OwnersScreen extends StatefulWidget {
  const OwnersScreen({super.key});

  @override
  State<OwnersScreen> createState() => _OwnersScreenState();
}

class _OwnersScreenState extends State<OwnersScreen> {
  late Future<List<Owner>> _ownersFuture;
  final OwnerService _ownerService = OwnerService();

  @override
  void initState() {
    super.initState();
    _ownersFuture = _ownerService.fetchOwners(); // تهيئة الـ Future فورًا
  }

  void _loadData() {
    setState(() {
      _ownersFuture = _ownerService.fetchOwners();
    });
  }

  void _deleteOwner(int id) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد الحذف'),
              content: Text('هل أنت متأكد أنك تريد حذف المالك برقم ID: $id؟'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('حذف', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (confirmed) {
      try {
        await _ownerService.deleteOwner(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المالك بنجاح!')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToAddEditScreen({Owner? owner}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditOwnerScreen(
          owner: owner,
          onSaved: _loadData,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4.0)),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('إدارة الملاك', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.indigo.shade800,
          actions: [
            _buildActionButton(
              text: 'تحديث',
              icon: Icons.refresh,
              color: Colors.blue.shade700,
              onPressed: _loadData,
            ),
            _buildActionButton(
              text: 'إضافة مالك',
              icon: Icons.add,
              color: Colors.green.shade600,
              onPressed: () => _navigateToAddEditScreen(),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<Owner>>(
            future: _ownersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('لا توجد بيانات للملاك متوفرة.', style: TextStyle(color: Colors.grey)));
              }

              final owners = snapshot.data!;
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.grey.shade50),
                    columns: const [
                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الاسم', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الحساب البنكي', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('العمليات', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: owners.map((owner) {
                      return DataRow(cells: [
                        DataCell(Text(owner.id.toString())),
                        DataCell(Text(owner.name)),
                        DataCell(Text(owner.bankAccount ?? '-')),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue.shade700, size: 20),
                              onPressed: () => _navigateToAddEditScreen(owner: owner),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _deleteOwner(owner.id),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// *****************************************************************************
// 5. MAIN
// *****************************************************************************
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://yvdaupqwzxaoqygkxlii.supabase.co',
    anonKey: 'NEXT_PUBLIC_SUPABASE_ANON_KEY',
  );

  runApp(const MaterialApp(
    title: 'Owners Management',
    home: OwnersScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

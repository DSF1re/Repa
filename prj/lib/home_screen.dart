import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'patient_screen.dart';
import 'doctor_screen.dart';
import 'schedule_screen.dart';
import 'main.dart';
import 'booking_screen.dart';
import 'unconfirmed_patients_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _userRole;

  final List<Widget> _screens = [
    const HomeContentScreen(),
    const PatientsScreen(),
    const DoctorsScreen(),
    const ScheduleScreen(),
    const UnconfirmedPatientsScreen(),
  ];

  final List<String> _titles = [
    'Главная',
    'Пациенты',
    'Врачи',
    'Расписание',
    'Неподтвержденные пациенты',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response =
          await supabase
              .from('User')
              .select('Role')
              .eq('ID_User', user.id)
              .single();
      setState(() {
        _userRole = response['Role'] as String?;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await supabase.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        elevation: 2,
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _screens[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 240,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurpleAccent],
              ),
            ),
            child: Text(
              'Меню',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDrawerItem(0, Icons.home, 'Главная'),
          if (_userRole == 'Пациент' || _userRole == 'Администратор') ...[
            _buildDrawerItem(1, Icons.people, 'Пациенты'),
            _buildDrawerItem(2, Icons.medical_services, 'Врачи'),
            _buildDrawerItem(3, Icons.calendar_today, 'Расписание'),
          ],
          if (_userRole == 'Администратор')
            _buildDrawerItem(
              4,
              Icons.verified_user,
              'Неподтвержденные пациенты',
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.deepPurple.shade50,
      onTap: () {
        _onItemTapped(index);
        Navigator.pop(context);
      },
    );
  }
}

class HomeContentScreen extends StatelessWidget {
  const HomeContentScreen({super.key});

  Future<List<Map<String, dynamic>>> fetchServices() async {
    final response = await supabase.from('Service').select();
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blueAccent, Colors.deepPurpleAccent],
        ),
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Услуги не найдены',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final services = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: services.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return ServiceListTile(service: services[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ServiceListTile extends StatelessWidget {
  final Map<String, dynamic> service;

  const ServiceListTile({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.medical_services,
            color: Colors.deepPurple,
            size: 28,
          ),
        ),
        title: Text(
          service['Name'] ?? '',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle:
            service['Description'] != null
                ? Text(
                  service['Description'] ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
                : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              service['Price'] != null ? '${service['Price']} ₽' : '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Text(
              'за сеанс',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingScreen(service: service),
            ),
          );
        },
      ),
    );
  }
}

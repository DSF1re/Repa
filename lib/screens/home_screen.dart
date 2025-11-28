import 'package:clinic_app/screens/doctor_screen.dart';
import 'package:clinic_app/screens/patient_screen.dart';
import 'package:clinic_app/screens/schedule_screen.dart';
import 'package:clinic_app/screens/service_cart.dart';
import 'package:clinic_app/screens/unconfirmed_patients_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/services/services_bloc.dart';
import '../repositories/service_repository.dart';
import '../models/user_model.dart';
import '../models/service_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // ✅ Динамические заголовки в зависимости от роли
  List<String> _getTitles(UserRole userRole) {
    switch (userRole) {
      case UserRole.admin:
        return [
          'Наши услуги',
          'Пациенты',
          'Врачи',
          'Расписание',
          'Неподтвержденные пациенты',
        ];
      case UserRole.doctor:
        return ['Наши услуги', 'Пациенты', 'Врачи', 'Расписание'];
      case UserRole.patient:
        return ['Наши услуги', 'Врачи', 'Расписание'];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ✅ Получение экрана с учетом роли пользователя
  Widget _getScreen(int index, UserRole userRole) {
    switch (userRole) {
      case UserRole.admin:
        switch (index) {
          case 0:
            return const HomeContentScreen();
          case 1:
            return const PatientsScreen();
          case 2:
            return const DoctorsScreen();
          case 3:
            return const ScheduleScreen();
          case 4:
            return const UnconfirmedPatientsScreen();
          default:
            return const HomeContentScreen();
        }
      case UserRole.doctor:
        switch (index) {
          case 0:
            return const HomeContentScreen();
          case 1:
            return const PatientsScreen();
          case 2:
            return const DoctorsScreen();
          case 3:
            return const ScheduleScreen();
          default:
            return const HomeContentScreen();
        }
      case UserRole.patient:
        switch (index) {
          case 0:
            return const HomeContentScreen();
          case 1:
            return const DoctorsScreen();
          case 2:
            return const ScheduleScreen();
          default:
            return const HomeContentScreen();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppAuthBloc, AppAuthState>(
      builder: (context, authState) {
        if (authState.status != AppAuthStatus.authenticated ||
            authState.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user!;
        final titles = _getTitles(user.role);

        return Scaffold(
          appBar: AppBar(
            title: Text(titles[_selectedIndex]),
            elevation: 0,
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () =>
                    context.read<AppAuthBloc>().add(AppAuthSignOutRequested()),
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
          drawer: _buildDrawer(user.role),
          body: _getScreen(_selectedIndex, user.role),
        );
      },
    );
  }

  Widget _buildDrawer(UserRole userRole) {
    return Drawer(
      width: 280,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF5F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withAlpha(75),
                    child: const Icon(
                      Icons.local_hospital,
                      size: 35,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Медицинская клиника',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Услуги - для всех ролей
            _buildDrawerItem(0, Icons.medical_services, 'Услуги', Colors.blue),

            // ✅ Пациенты - только для врачей и админов
            if (userRole == UserRole.doctor || userRole == UserRole.admin)
              _buildDrawerItem(1, Icons.people, 'Пациенты', Colors.green),

            // ✅ Врачи - для всех ролей (с разными индексами)
            if (userRole == UserRole.admin || userRole == UserRole.doctor)
              _buildDrawerItem(
                2,
                Icons.medical_information,
                'Врачи',
                Colors.orange,
              )
            else if (userRole == UserRole.patient)
              _buildDrawerItem(
                1,
                Icons.medical_information,
                'Врачи',
                Colors.orange,
              ),

            if (userRole == UserRole.admin || userRole == UserRole.doctor)
              _buildDrawerItem(
                3,
                Icons.calendar_today,
                'Расписание',
                Colors.purple,
              )
            else if (userRole == UserRole.patient)
              _buildDrawerItem(
                2,
                Icons.calendar_today,
                'Расписание',
                Colors.purple,
              ),

            if (userRole == UserRole.admin)
              _buildDrawerItem(
                4,
                Icons.verified_user,
                'Неподтвержденные',
                Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title, Color color) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? color.withAlpha(25) : Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isSelected ? Colors.white : color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color : Colors.grey.shade700,
          ),
        ),
        selected: isSelected,
        onTap: () {
          _onItemTapped(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class HomeContentScreen extends StatelessWidget {
  const HomeContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ServicesBloc(
        serviceRepository: RepositoryProvider.of<ServiceRepository>(context),
      )..add(ServicesLoadRequested()),
      child: const ServicesView(),
    );
  }
}

class ServicesView extends StatelessWidget {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: BlocBuilder<ServicesBloc, ServicesState>(
        builder: (context, state) {
          switch (state.status) {
            case ServicesStatus.loading:
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Загружаем услуги...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            case ServicesStatus.failure:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ошибка загрузки услуг',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Попробуйте еще раз',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Повторить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context.read<ServicesBloc>().add(
                        ServicesLoadRequested(),
                      ),
                    ),
                  ],
                ),
              );
            case ServicesStatus.success:
              if (state.services.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.medical_services_outlined,
                          size: 64,
                          color: Colors.orange.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Услуги не найдены',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'В данный момент услуги недоступны',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return AdaptiveServicesGrid(services: state.services);
            case ServicesStatus.initial:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class AdaptiveServicesGrid extends StatelessWidget {
  final List<ServiceModel> services;

  const AdaptiveServicesGrid({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (screenWidth > 1200) {
      crossAxisCount = 3;
    } else if (screenWidth > 800) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ServicesBloc>().add(ServicesLoadRequested());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: MasonryGridView.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                itemCount: services.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: ServiceCard(service: services[index], index: index),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

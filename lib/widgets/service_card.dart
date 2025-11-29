import 'package:clinic_app/models/service_model.dart';
import 'package:clinic_app/screens/booking_screen.dart';
import 'package:flutter/material.dart';

class ServiceCard extends StatefulWidget {
  final ServiceModel service;
  final int index;

  const ServiceCard({super.key, required this.service, required this.index});

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradients = [
      [Colors.blue.shade400, Colors.blue.shade600],
      [Colors.green.shade400, Colors.green.shade600],
      [Colors.orange.shade400, Colors.orange.shade600],
      [Colors.purple.shade400, Colors.purple.shade600],
      [Colors.teal.shade400, Colors.teal.shade600],
      [Colors.pink.shade400, Colors.pink.shade600],
    ];

    final gradient = gradients[widget.index % gradients.length];

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) {
              setState(() => _isHovered = true);
              _animationController.forward();
            },
            onExit: (_) {
              setState(() => _isHovered = false);
              _animationController.reverse();
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookingScreen(service: widget.service),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withAlpha(75),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: _isHovered
                          ? const Offset(0, 10)
                          : const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -20,
                          right: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getServiceIcon(widget.service.name),
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.service.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              if (widget.service.description != null)
                                Text(
                                  widget.service.description!,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(225),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${widget.service.price.toStringAsFixed(0)} ₽',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'за сеанс',
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(200),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(50),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getServiceIcon(String serviceName) {
    final name = serviceName.toLowerCase();

    if (name.contains('консультация') || name.contains('прием')) {
      return Icons.person_search;
    } else if (name.contains('узи') || name.contains('диагностика')) {
      return Icons.monitor_heart;
    } else if (name.contains('анализ') || name.contains('кровь')) {
      return Icons.science;
    } else if (name.contains('массаж') || name.contains('терапия')) {
      return Icons.healing;
    } else if (name.contains('операция') || name.contains('хирургия')) {
      return Icons.local_hospital;
    } else if (name.contains('вакцинация') || name.contains('прививка')) {
      return Icons.vaccines;
    } else {
      return Icons.medical_services;
    }
  }
}

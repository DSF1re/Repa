import 'package:flutter/material.dart';

class BookingScreen extends StatelessWidget {
  final Map<String, dynamic> service;

  const BookingScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Оформление')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service['Name'], style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(service['Description'], style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text(
              'Цена: ${service['Price']} ₽',
              style: const TextStyle(fontSize: 18, color: Colors.deepPurple),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Записаться',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

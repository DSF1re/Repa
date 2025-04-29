import 'package:flutter/material.dart';

void main() {
  runApp(const CryptoCurrenciesListApp());
}

class CryptoCurrenciesListApp extends StatelessWidget {
  const CryptoCurrenciesListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {'/': (context) => HomePage(), '/gg': (context) => MyWidget()},
      theme: ThemeData(
        dividerColor: Colors.white24,
        primarySwatch: Colors.blue,
        fontFamily: 'Manrope',
        scaffoldBackgroundColor: const Color.fromARGB(255, 30, 30, 30),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
          labelSmall: TextStyle(
            color: Colors.white60,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 30, 30, 30),
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            fontSize: 22,
          ),
        ),
      ),
      debugShowMaterialGrid: false,
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('CryptoCurrenciesList')),
      body: ListView.separated(
        itemCount: 10,
        separatorBuilder:
            (context, index) => Divider(color: theme.dividerColor),
        itemBuilder:
            (context, i) => ListTile(
              leading: Icon(Icons.currency_bitcoin, color: Colors.white),
              title: Text('Bitcoin', style: theme.textTheme.bodyMedium),
              subtitle: Text('100000\$', style: theme.textTheme.labelSmall),
              trailing: IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/gg');
                },
                icon: Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ),
      ),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('gg'),
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}

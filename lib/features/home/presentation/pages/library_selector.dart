import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc_implementation/home/presentation/pages/bloc_home_page.dart';
import '../../../getx_implementation/home/presentation/pages/getx_home_page.dart';
import '../../../bloc_implementation/theme/bloc/theme_bloc.dart';
import '../../../bloc_implementation/home/bloc/home_bloc.dart';

class LibrarySelectorPage extends StatelessWidget {
  const LibrarySelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MovieDB Benchmark'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Wybierz bibliotekę do testowania:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildLibraryCard(
                context,
                title: 'BLoC',
                description: 'Business Logic Component\nStrumienie danych, niemutowalne stany',
                color: Colors.blue,
                onTap: () => _navigateToBlocImplementation(context),
              ),
              const SizedBox(height: 20),
              _buildLibraryCard(
                context,
                title: 'GetX',
                description: 'Reactive State Management\nReaktywne zmienne, prostota',
                color: Colors.purple,
                onTap: () => _navigateToGetXImplementation(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBlocImplementation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => ThemeBloc()),
            BlocProvider(create: (context) => HomeBloc()),
          ],
          child: const BlocHomePage(),
        ),
      ),
    );
  }

  void _navigateToGetXImplementation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GetXHomePage(),
      ),
    );
  }
}
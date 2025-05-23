import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'core/api/tmdb_api_client.dart';
import 'features/home/presentation/pages/library_selector_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => TmdbApiClient(),
        ),
      ],
      child: GetMaterialApp(
        title: 'MovieDB Benchmark - BLoC vs GetX',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
        ),
        home: const LibrarySelectorPage(),
      ),
    );
  }
}
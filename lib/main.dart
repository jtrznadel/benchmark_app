import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviedb_benchmark_bloc/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark_bloc/features/theme/bloc/theme_state.dart';
import 'features/home/bloc/home_bloc.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/theme/bloc/theme_bloc.dart';

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
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ThemeBloc(),
          ),
          BlocProvider(
            create: (context) => HomeBloc(),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'MovieDB Benchmark - BLoC',
              theme: themeState.themeData,
              home: const HomePage(),
            );
          },
        ),
      ),
    );
  }
}

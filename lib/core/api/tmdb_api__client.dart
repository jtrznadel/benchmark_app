import 'package:dio/dio.dart';
import 'api_constants.dart';
import '../models/movie.dart';

class TmdbApiClient {
  late final Dio _dio;

  TmdbApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Authorization': 'Bearer ${ApiConstants.apiKey}',
        'Content-Type': 'application/json',
      },
    ));
  }

  Future<List<Movie>> getPopularMovies({required int page}) async {
    try {
      final response = await _dio.get(
        '/movie/popular',
        queryParameters: {'page': page},
      );
      
      final movies = (response.data['results'] as List)
          .map((json) => Movie.fromJson(json))
          .toList();
      
      return movies;
    } catch (e) {
      throw Exception('Failed to load movies: $e');
    }
  }

  Future<List<Movie>> loadAllMovies({required int totalItems}) async {
    final List<Movie> allMovies = [];
    final int totalPages = (totalItems / ApiConstants.pageSize).ceil();
    
    for (int page = 1; page <= totalPages; page++) {
      final movies = await getPopularMovies(page: page);
      allMovies.addAll(movies);
      
      if (allMovies.length >= totalItems) {
        return allMovies.take(totalItems).toList();
      }
    }
    
    return allMovies;
  }
}
import 'package:flutter/material.dart';
import 'package:moviedb_benchmark_bloc/core/api/api_constants.dart';
import 'package:moviedb_benchmark_bloc/core/api/models/movie.dart';

class MovieGridItem extends StatelessWidget {
  final Movie movie;
  final bool isExpanded;
  final VoidCallback onTap;

  const MovieGridItem({
    super.key,
    required this.movie,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movie.posterPath != null)
              Expanded(
                flex: isExpanded ? 3 : 4,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  child: Image.network(
                    '${ApiConstants.imageBaseUrl}${movie.posterPath}',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.movie, size: 48),
                        ),
                      );
                    },
                  ),
                ),
              ),
            Expanded(
              flex: isExpanded ? 2 : 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: isExpanded ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (isExpanded)
                      Expanded(
                        child: Text(
                          movie.overview,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

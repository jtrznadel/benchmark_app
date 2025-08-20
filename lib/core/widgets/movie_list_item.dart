import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../api/api_constants.dart';
import '../utils/uir_tracker.dart'; // DODANE

class MovieListItem extends StatelessWidget {
  final Movie movie;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isAccessibilityMode;

  const MovieListItem({
    super.key,
    required this.movie,
    required this.isExpanded,
    required this.onTap,
    this.isAccessibilityMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // DODANE - UIR tracking
    UIRTracker.markWidgetRebuild('MovieListItem_${movie.id}', 'movies_update');

    return Card(
      // reszta bez zmian...
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isAccessibilityMode ? 12.0 : 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (movie.posterPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '${ApiConstants.imageBaseUrl}${movie.posterPath}',
                    width: 60,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 90,
                        color: Colors.grey[300],
                        child: const Icon(Icons.movie),
                      );
                    },
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: isAccessibilityMode
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.titleMedium,
                      maxLines: isExpanded ? null : 1,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          movie.releaseDate.split('-').first,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 8),
                      Text(
                        movie.overview,
                        style: isAccessibilityMode
                            ? Theme.of(context).textTheme.bodyLarge
                            : Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

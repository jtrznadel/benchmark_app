import 'package:flutter/material.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';
import '../models/movie.dart';
import '../api/api_constants.dart';

class MovieGridItem extends StatelessWidget {
  final Movie movie;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isAccessibilityMode;

  const MovieGridItem({
    super.key,
    required this.movie,
    required this.isExpanded,
    required this.onTap,
    this.isAccessibilityMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // ZMIANA - proste counting
    UIPerformanceTracker.markWidgetRebuild();

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
                padding: EdgeInsets.all(isAccessibilityMode ? 12.0 : 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: isAccessibilityMode
                          ? Theme.of(context).textTheme.titleMedium
                          : Theme.of(context).textTheme.titleSmall,
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

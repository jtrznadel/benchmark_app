import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/ui_element_state.dart';

class FairMovieCard extends StatelessWidget {
  final Movie movie;
  final UIElementState uiState;
  final VoidCallback? onLikeTap;
  final VoidCallback? onDownloadTap;

  const FairMovieCard({
    super.key,
    required this.movie,
    required this.uiState,
    this.onLikeTap,
    this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            uiState.isHighlighted ? Colors.blue.withOpacity(0.1) : Colors.white,
        border: Border.all(
          color: uiState.isFeatured ? Colors.amber : Colors.grey[300]!,
          width: uiState.isFeatured ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  movie.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: uiState.isFeatured
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (uiState.popularityScore > 80)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'HOT',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Interactive elements row
          Row(
            children: [
              // Like button
              GestureDetector(
                onTap: onLikeTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: uiState.isLiked
                        ? Colors.red.withOpacity(0.2)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        uiState.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: uiState.isLiked ? Colors.red : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text('Like', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // View counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${uiState.viewCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            uiState.viewCount > 100 ? Colors.blue : Colors.grey,
                        fontWeight:
                            uiState.viewCount > 100 ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Rating
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(5, (index) {
                    final starValue = index + 1;
                    return Icon(
                      starValue <= uiState.rating
                          ? Icons.star
                          : Icons.star_border,
                      size: 14,
                      color: Colors.amber,
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(
                    uiState.rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress: ${(uiState.progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              LinearProgressIndicator(
                value: uiState.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  uiState.progress >= 1.0 ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Bottom row
          Row(
            children: [
              // Download button
              GestureDetector(
                onTap: onDownloadTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: uiState.isDownloading ? Colors.orange : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    uiState.isDownloading ? 'Downloading' : 'Download',
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ),

              const Spacer(),

              // Stats
              Text(
                'Pop: ${uiState.popularityScore} | Watched: ${uiState.isWatched}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

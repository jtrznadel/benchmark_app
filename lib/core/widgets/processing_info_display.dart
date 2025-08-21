import 'package:flutter/material.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';
import '../models/processing_state.dart';

class ProcessingInfoDisplay extends StatelessWidget {
  final ProcessingState processingState;
  final int cycleCount;
  final String scenarioName;

  const ProcessingInfoDisplay({
    super.key,
    required this.processingState,
    required this.cycleCount,
    required this.scenarioName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scenarioName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Cycle', cycleCount.toString()),
          _buildInfoRow('Step', '${processingState.processingStep}/5'),
          _buildInfoRow('Current Genre', processingState.currentGenre),
          _buildInfoRow('Filtered Movies',
              processingState.filteredMovies.length.toString()),
          _buildInfoRow(
              'Sorted Movies', processingState.sortedMovies.length.toString()),
          _buildInfoRow(
              'Groups', processingState.groupedMovies.keys.length.toString()),
          if (processingState.calculatedMetrics.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildMetricsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calculated Metrics:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...processingState.calculatedMetrics.entries.map(
          (entry) => _buildInfoRow(
            entry.key,
            entry.value.toStringAsFixed(2),
          ),
        ),
      ],
    );
  }
}

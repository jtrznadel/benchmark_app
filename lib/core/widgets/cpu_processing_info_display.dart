import 'package:flutter/material.dart';
import '../models/cpu_processing_state.dart';

class CpuProcessingInfoDisplay extends StatelessWidget {
  final CpuProcessingState cpuProcessingState;
  final String scenarioName;

  const CpuProcessingInfoDisplay({
    super.key,
    required this.cpuProcessingState,
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
          _buildInfoRow('Cycle', '${cpuProcessingState.cycleCount}/600'),
          _buildInfoRow(
              'Processing Step', '${cpuProcessingState.processingStep}/5'),
          _buildInfoRow('Current Genre', cpuProcessingState.currentGenre),
          _buildInfoRow(
              'Current Sort Type', cpuProcessingState.currentSortType),
          _buildInfoRow(
              'Current Group Type', cpuProcessingState.currentGroupType),
          _buildInfoRow('Filtered Movies',
              cpuProcessingState.filteredMovies.length.toString()),
          _buildInfoRow('Sorted Movies',
              cpuProcessingState.sortedMovies.length.toString()),
          _buildInfoRow('Groups',
              cpuProcessingState.groupedMovies.keys.length.toString()),
          if (cpuProcessingState.calculatedMetrics.isNotEmpty) ...[
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
        ...cpuProcessingState.calculatedMetrics.entries.map(
          (entry) => _buildInfoRow(
            _formatMetricName(entry.key),
            entry.value.toStringAsFixed(3),
          ),
        ),
      ],
    );
  }

  String _formatMetricName(String key) {
    switch (key) {
      case 'averageRating':
        return 'Avg Rating';
      case 'weightedAverage':
        return 'Weighted Avg';
      case 'complexityIndex':
        return 'Complexity';
      case 'totalMovies':
        return 'Total Movies';
      default:
        return key;
    }
  }
}

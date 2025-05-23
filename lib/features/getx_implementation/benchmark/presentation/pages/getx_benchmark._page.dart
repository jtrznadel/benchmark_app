import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/benchmark_controller.dart';
import '../widgets/getx_benchmark_controls.dart';
import '../../../../../core/widgets/movie_list_item.dart';
import '../../../../../core/widgets/movie_grid_item.dart';

class GetXBenchmarkPage extends StatelessWidget {
  final String scenarioId;
  final int dataSize;

  const GetXBenchmarkPage({
    super.key,
    required this.scenarioId,
    required this.dataSize,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BenchmarkController());
        WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.startBenchmark(scenarioId, dataSize);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('GetX Benchmark: $scenarioId'),
        backgroundColor: Colors.purple,
        actions: [
          Obx(() {
            if (controller.status.value == BenchmarkStatus.running ||
                controller.status.value == BenchmarkStatus.loaded) {
              return IconButton(
                icon: Icon(
                  controller.viewMode.value == ViewMode.list
                      ? Icons.grid_view
                      : Icons.list,
                ),
                onPressed: controller.toggleViewMode,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.status.value == BenchmarkStatus.loading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.purple),
                SizedBox(height: 16),
                Text('Ładowanie danych...'),
              ],
            ),
          );
        }

        if (controller.status.value == BenchmarkStatus.error) {
          return Center(
            child: Text(
              'Błąd: ${controller.error.value}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return Column(
          children: [
            GetXBenchmarkControls(
              scenarioId: scenarioId,
              controller: controller,
            ),
            Expanded(
              child: _buildMovieView(controller),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMovieView(BenchmarkController controller) {
    if (controller.filteredMovies.isEmpty) {
      return const Center(child: Text('Brak filmów do wyświetlenia'));
    }

    final scrollController = ScrollController();

    if (scenarioId == 'S02' && controller.isAutoScrolling.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(seconds: 2),
            curve: Curves.linear,
          );
        }
      });
    }

    return Obx(() {
      if (controller.viewMode.value == ViewMode.grid) {
        return GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: controller.filteredMovies.length,
          itemBuilder: (context, index) {
            final movie = controller.filteredMovies[index];
            return Obx(() => MovieGridItem(
              movie: movie,
              isExpanded: controller.expandedMovies.contains(movie.id),
              isAccessibilityMode: controller.isAccessibilityMode.value,
              onTap: () => controller.toggleMovieExpanded(movie.id),
            ));
          },
        );
      } else {
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(8),
          itemCount: controller.filteredMovies.length,
          itemBuilder: (context, index) {
            final movie = controller.filteredMovies[index];
            
            if (scenarioId == 'S02' &&
                index == controller.filteredMovies.length - 5 &&
                controller.loadedCount.value < dataSize) {
              controller.loadMoreMovies();
            }
            
            return Obx(() => MovieListItem(
              movie: movie,
              isExpanded: controller.expandedMovies.contains(movie.id),
              isAccessibilityMode: controller.isAccessibilityMode.value,
              onTap: () => controller.toggleMovieExpanded(movie.id),
            ));
          },
        );
      }
    });
  }
}
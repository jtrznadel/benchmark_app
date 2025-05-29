import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviedb_benchmark/features/getx_implementation/benchmark/presentation/controllers/benchmark_controller.dart';
import '../widgets/getx_benchmark_controls.dart';
import '../../../../../core/widgets/movie_list_item.dart';
import '../../../../../core/widgets/movie_grid_item.dart';

class GetXBenchmarkPage extends StatefulWidget {
  final String scenarioId;
  final int dataSize;

  const GetXBenchmarkPage({
    super.key,
    required this.scenarioId,
    required this.dataSize,
  });

  @override
  State<GetXBenchmarkPage> createState() => _GetXBenchmarkPageState();
}

class _GetXBenchmarkPageState extends State<GetXBenchmarkPage> {
  late ScrollController _scrollController;
  final controller = Get.put(BenchmarkController());

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.startBenchmark(widget.scenarioId, widget.dataSize);
      
      if (widget.scenarioId == 'S02') {
        _startAutoScroll();
      }
    });
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && controller.isAutoScrolling.value) {
        _animateScroll();
      }
    });
  }

  void _animateScroll() {
    if (!_scrollController.hasClients || !controller.isAutoScrolling.value) return;
    
    final double targetPosition = _scrollController.position.maxScrollExtent;
    final double currentPosition = _scrollController.position.pixels;
    
    if (currentPosition < targetPosition) {
      _scrollController.animateTo(
        targetPosition,
        duration: Duration(milliseconds: ((targetPosition - currentPosition) * 3).toInt()),
        curve: Curves.linear,
      ).then((_) {
        if (controller.isAutoScrolling.value && controller.loadedCount.value < widget.dataSize) {
          Future.delayed(const Duration(milliseconds: 100), _animateScroll);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GetX Benchmark: ${widget.scenarioId}'),
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
              scenarioId: widget.scenarioId,
              controller: controller,
            ),
            Expanded(
              child: _buildMovieView(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMovieView() {
    if (controller.filteredMovies.isEmpty) {
      return const Center(child: Text('Brak filmów do wyświetlenia'));
    }

    return Obx(() {
      if (controller.viewMode.value == ViewMode.grid) {
        return GridView.builder(
          controller: _scrollController,
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
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          itemCount: controller.filteredMovies.length,
          itemBuilder: (context, index) {
            final movie = controller.filteredMovies[index];

            if (widget.scenarioId == 'S02' &&
                index == controller.filteredMovies.length - 5 &&
                controller.loadedCount.value < widget.dataSize) {
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
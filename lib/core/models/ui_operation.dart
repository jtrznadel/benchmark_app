import 'package:equatable/equatable.dart';

class UIOperation extends Equatable {
  final UIOperationType type;
  final List<int> movieIds;
  final dynamic value;

  const UIOperation(this.type, this.movieIds, [this.value]);

  @override
  List<Object?> get props => [type, movieIds, value];
}

enum UIOperationType {
  like,
  progress,
  rating,
  download,
  viewCount,
  batch,
  cascade,
  animation
}

part of 'trash_bloc.dart';

abstract class TrashState extends Equatable {
  const TrashState();

  @override
  List<Object?> get props => [];
}

class TrashInitial extends TrashState {
  const TrashInitial();
}

class TrashLoading extends TrashState {
  const TrashLoading();
}

class TrashLoaded extends TrashState {
  final List<TrashItem> items;
  const TrashLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class TrashOperationInProgress extends TrashState {
  const TrashOperationInProgress();
}

class TrashOperationSuccess extends TrashState {
  final String message;
  const TrashOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TrashError extends TrashState {
  final String message;
  const TrashError(this.message);

  @override
  List<Object?> get props => [message];
}

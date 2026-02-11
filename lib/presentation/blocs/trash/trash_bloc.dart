import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/trash_item.dart';
import '../../../core/repositories/trash_repository.dart';

part 'trash_event.dart';
part 'trash_state.dart';

class TrashBloc extends Bloc<TrashEvent, TrashState> {
  final TrashRepository _repository;

  TrashBloc(this._repository) : super(const TrashInitial()) {
    on<LoadTrash>(_onLoadTrash);
    on<RestoreTrashItem>(_onRestore);
    on<DeleteTrashItemPermanently>(_onDeletePermanently);
    on<EmptyTrashRequested>(_onEmptyTrash);
  }

  Future<void> _onLoadTrash(
    LoadTrash event,
    Emitter<TrashState> emit,
  ) async {
    emit(const TrashLoading());
    final result = await _repository.listTrash();
    result.fold(
      (failure) => emit(TrashError(failure.message)),
      (items) => emit(TrashLoaded(items)),
    );
  }

  Future<void> _onRestore(
    RestoreTrashItem event,
    Emitter<TrashState> emit,
  ) async {
    emit(const TrashOperationInProgress());
    final result = await _repository.restoreItem(event.trashId);
    result.fold(
      (failure) => emit(TrashError(failure.message)),
      (_) {
        emit(const TrashOperationSuccess('Item restored successfully'));
        add(const LoadTrash()); // Reload list
      },
    );
  }

  Future<void> _onDeletePermanently(
    DeleteTrashItemPermanently event,
    Emitter<TrashState> emit,
  ) async {
    emit(const TrashOperationInProgress());
    final result = await _repository.deleteItemPermanently(event.trashId);
    result.fold(
      (failure) => emit(TrashError(failure.message)),
      (_) {
        emit(const TrashOperationSuccess('Item deleted permanently'));
        add(const LoadTrash());
      },
    );
  }

  Future<void> _onEmptyTrash(
    EmptyTrashRequested event,
    Emitter<TrashState> emit,
  ) async {
    emit(const TrashOperationInProgress());
    final result = await _repository.emptyTrash();
    result.fold(
      (failure) => emit(TrashError(failure.message)),
      (_) {
        emit(const TrashOperationSuccess('Trash emptied'));
        add(const LoadTrash());
      },
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/share_item.dart';
import '../../../core/repositories/share_repository.dart';

part 'share_event.dart';
part 'share_state.dart';

class ShareBloc extends Bloc<ShareEvent, ShareState> {
  final ShareRepository _repository;

  ShareBloc(this._repository) : super(const ShareInitial()) {
    on<LoadShares>(_onLoadShares);
    on<CreateShareRequested>(_onCreateShare);
    on<UpdateShareRequested>(_onUpdateShare);
    on<DeleteShareRequested>(_onDeleteShare);
    on<LoadMoreShares>(_onLoadMore);
  }

  int _currentPage = 1;
  static const int _perPage = 20;

  Future<void> _onLoadShares(
    LoadShares event,
    Emitter<ShareState> emit,
  ) async {
    emit(const ShareLoading());
    _currentPage = 1;
    final result =
        await _repository.listShares(page: _currentPage, perPage: _perPage);
    result.fold(
      (failure) => emit(ShareError(failure.message)),
      (paginated) => emit(ShareLoaded(
        shares: paginated.items,
        pagination: paginated.pagination,
      )),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreShares event,
    Emitter<ShareState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ShareLoaded || !currentState.pagination.hasNext) {
      return;
    }
    _currentPage++;
    final result =
        await _repository.listShares(page: _currentPage, perPage: _perPage);
    result.fold(
      (failure) {
        _currentPage--;
        emit(ShareError(failure.message));
      },
      (paginated) => emit(ShareLoaded(
        shares: [...currentState.shares, ...paginated.items],
        pagination: paginated.pagination,
      )),
    );
  }

  Future<void> _onCreateShare(
    CreateShareRequested event,
    Emitter<ShareState> emit,
  ) async {
    emit(const ShareOperationInProgress());
    final result = await _repository.createShare(
      itemId: event.itemId,
      itemType: event.itemType,
      password: event.password,
      expiresAt: event.expiresAt,
      permissions: event.permissions,
    );
    result.fold(
      (failure) => emit(ShareError(failure.message)),
      (share) {
        emit(ShareCreated(share));
        add(const LoadShares()); // Reload list
      },
    );
  }

  Future<void> _onUpdateShare(
    UpdateShareRequested event,
    Emitter<ShareState> emit,
  ) async {
    emit(const ShareOperationInProgress());
    final result = await _repository.updateShare(
      id: event.shareId,
      password: event.password,
      expiresAt: event.expiresAt,
      permissions: event.permissions,
    );
    result.fold(
      (failure) => emit(ShareError(failure.message)),
      (share) {
        emit(ShareUpdated(share));
        add(const LoadShares());
      },
    );
  }

  Future<void> _onDeleteShare(
    DeleteShareRequested event,
    Emitter<ShareState> emit,
  ) async {
    emit(const ShareOperationInProgress());
    final result = await _repository.deleteShare(event.shareId);
    result.fold(
      (failure) => emit(ShareError(failure.message)),
      (_) {
        emit(const ShareOperationSuccess('Share deleted'));
        add(const LoadShares());
      },
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/favorite_item.dart';
import '../../../core/repositories/recent_repository.dart';

// Events
abstract class RecentEvent extends Equatable {
  const RecentEvent();
  @override
  List<Object?> get props => [];
}

class LoadRecent extends RecentEvent {
  const LoadRecent();
}

class ClearRecentRequested extends RecentEvent {
  const ClearRecentRequested();
}

// States
abstract class RecentState extends Equatable {
  const RecentState();
  @override
  List<Object?> get props => [];
}

class RecentInitial extends RecentState {
  const RecentInitial();
}

class RecentLoading extends RecentState {
  const RecentLoading();
}

class RecentLoaded extends RecentState {
  const RecentLoaded(this.items);
  final List<RecentItem> items;
  @override
  List<Object?> get props => [items];
}

class RecentError extends RecentState {
  const RecentError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// BLoC
class RecentBloc extends Bloc<RecentEvent, RecentState> {
  final RecentRepository _repository;

  RecentBloc(this._repository) : super(const RecentInitial()) {
    on<LoadRecent>(_onLoad);
    on<ClearRecentRequested>(_onClear);
  }

  Future<void> _onLoad(LoadRecent event, Emitter<RecentState> emit) async {
    emit(const RecentLoading());
    final result = await _repository.getRecent();
    result.fold(
      (f) => emit(RecentError(f.message)),
      (items) => emit(RecentLoaded(items)),
    );
  }

  Future<void> _onClear(ClearRecentRequested event, Emitter<RecentState> emit) async {
    await _repository.clearRecent();
    add(const LoadRecent());
  }
}

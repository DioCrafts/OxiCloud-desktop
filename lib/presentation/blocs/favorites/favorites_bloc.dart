import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/favorite_item.dart';
import '../../../core/repositories/favorites_repository.dart';

// Events
abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();
  @override
  List<Object?> get props => [];
}

class LoadFavorites extends FavoritesEvent {
  const LoadFavorites();
}

class AddFavorite extends FavoritesEvent {
  const AddFavorite({required this.itemType, required this.itemId});
  final String itemType;
  final String itemId;
  @override
  List<Object?> get props => [itemType, itemId];
}

class RemoveFavorite extends FavoritesEvent {
  final String itemType;
  final String itemId;
  const RemoveFavorite({required this.itemType, required this.itemId});
  @override
  List<Object?> get props => [itemType, itemId];
}

// States
abstract class FavoritesState extends Equatable {
  const FavoritesState();
  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  final List<FavoriteItem> items;
  const FavoritesLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class FavoritesError extends FavoritesState {
  final String message;
  const FavoritesError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository _repository;

  FavoritesBloc(this._repository) : super(const FavoritesInitial()) {
    on<LoadFavorites>(_onLoad);
    on<AddFavorite>(_onAdd);
    on<RemoveFavorite>(_onRemove);
  }

  Future<void> _onLoad(LoadFavorites event, Emitter<FavoritesState> emit) async {
    emit(const FavoritesLoading());
    final result = await _repository.getFavorites();
    result.fold(
      (f) => emit(FavoritesError(f.message)),
      (items) => emit(FavoritesLoaded(items)),
    );
  }

  Future<void> _onAdd(AddFavorite event, Emitter<FavoritesState> emit) async {
    await _repository.addFavorite(event.itemType, event.itemId);
    add(const LoadFavorites());
  }

  Future<void> _onRemove(RemoveFavorite event, Emitter<FavoritesState> emit) async {
    await _repository.removeFavorite(event.itemType, event.itemId);
    add(const LoadFavorites());
  }
}

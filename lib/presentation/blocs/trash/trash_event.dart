part of 'trash_bloc.dart';

abstract class TrashEvent extends Equatable {
  const TrashEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrash extends TrashEvent {
  const LoadTrash();
}

class RestoreTrashItem extends TrashEvent {
  final String trashId;
  const RestoreTrashItem(this.trashId);

  @override
  List<Object?> get props => [trashId];
}

class DeleteTrashItemPermanently extends TrashEvent {
  final String trashId;
  const DeleteTrashItemPermanently(this.trashId);

  @override
  List<Object?> get props => [trashId];
}

class EmptyTrashRequested extends TrashEvent {
  const EmptyTrashRequested();
}

part of 'share_bloc.dart';

abstract class ShareState extends Equatable {
  const ShareState();

  @override
  List<Object?> get props => [];
}

class ShareInitial extends ShareState {
  const ShareInitial();
}

class ShareLoading extends ShareState {
  const ShareLoading();
}

class ShareLoaded extends ShareState {
  final List<ShareItem> shares;
  final PaginationInfo pagination;

  const ShareLoaded({
    required this.shares,
    required this.pagination,
  });

  @override
  List<Object?> get props => [shares, pagination];
}

class ShareOperationInProgress extends ShareState {
  const ShareOperationInProgress();
}

class ShareCreated extends ShareState {
  final ShareItem share;
  const ShareCreated(this.share);

  @override
  List<Object?> get props => [share];
}

class ShareUpdated extends ShareState {
  final ShareItem share;
  const ShareUpdated(this.share);

  @override
  List<Object?> get props => [share];
}

class ShareOperationSuccess extends ShareState {
  final String message;
  const ShareOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ShareError extends ShareState {
  final String message;
  const ShareError(this.message);

  @override
  List<Object?> get props => [message];
}

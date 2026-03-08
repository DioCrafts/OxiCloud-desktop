import 'package:dartz/dartz.dart';
import '../entities/favorite_item.dart';

/// Recent files repository interface
abstract class RecentRepository {
  Future<Either<RecentFailure, List<RecentItem>>> getRecent();
  Future<Either<RecentFailure, void>> addRecent(String itemType, String itemId);
  Future<Either<RecentFailure, void>> clearRecent();
}

abstract class RecentFailure {
  final String message;
  const RecentFailure(this.message);
}

class NetworkRecentFailure extends RecentFailure {
  const NetworkRecentFailure(super.message);
}

class UnknownRecentFailure extends RecentFailure {
  const UnknownRecentFailure(super.message);
}

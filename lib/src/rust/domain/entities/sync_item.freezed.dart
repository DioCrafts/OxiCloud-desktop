// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncStatus {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() synced,
    required TResult Function() pending,
    required TResult Function() syncing,
    required TResult Function(ConflictInfo field0) conflict,
    required TResult Function(String field0) error,
    required TResult Function() ignored,
  }) {
    return switch (this) {
      SyncStatus_Synced() => synced(),
      SyncStatus_Pending() => pending(),
      SyncStatus_Syncing() => syncing(),
      SyncStatus_Conflict(:final field0) => conflict(field0),
      SyncStatus_Error(:final field0) => error(field0),
      SyncStatus_Ignored() => ignored(),
    };
  }

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? synced,
    TResult Function()? pending,
    TResult Function()? syncing,
    TResult Function(ConflictInfo field0)? conflict,
    TResult Function(String field0)? error,
    TResult Function()? ignored,
    required TResult Function() orElse,
  }) {
    return switch (this) {
      SyncStatus_Synced() => synced != null ? synced() : orElse(),
      SyncStatus_Pending() => pending != null ? pending() : orElse(),
      SyncStatus_Syncing() => syncing != null ? syncing() : orElse(),
      SyncStatus_Conflict(:final field0) =>
        conflict != null ? conflict(field0) : orElse(),
      SyncStatus_Error(:final field0) =>
        error != null ? error(field0) : orElse(),
      SyncStatus_Ignored() => ignored != null ? ignored() : orElse(),
    };
  }

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStatus_Synced value) synced,
    required TResult Function(SyncStatus_Pending value) pending,
    required TResult Function(SyncStatus_Syncing value) syncing,
    required TResult Function(SyncStatus_Conflict value) conflict,
    required TResult Function(SyncStatus_Error value) error,
    required TResult Function(SyncStatus_Ignored value) ignored,
  }) {
    return switch (this) {
      SyncStatus_Synced() => synced(this as SyncStatus_Synced),
      SyncStatus_Pending() => pending(this as SyncStatus_Pending),
      SyncStatus_Syncing() => syncing(this as SyncStatus_Syncing),
      SyncStatus_Conflict() => conflict(this as SyncStatus_Conflict),
      SyncStatus_Error() => error(this as SyncStatus_Error),
      SyncStatus_Ignored() => ignored(this as SyncStatus_Ignored),
    };
  }

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStatus_Synced value)? synced,
    TResult Function(SyncStatus_Pending value)? pending,
    TResult Function(SyncStatus_Syncing value)? syncing,
    TResult Function(SyncStatus_Conflict value)? conflict,
    TResult Function(SyncStatus_Error value)? error,
    TResult Function(SyncStatus_Ignored value)? ignored,
    required TResult Function() orElse,
  }) {
    return switch (this) {
      SyncStatus_Synced() =>
        synced != null ? synced(this as SyncStatus_Synced) : orElse(),
      SyncStatus_Pending() =>
        pending != null ? pending(this as SyncStatus_Pending) : orElse(),
      SyncStatus_Syncing() =>
        syncing != null ? syncing(this as SyncStatus_Syncing) : orElse(),
      SyncStatus_Conflict() =>
        conflict != null ? conflict(this as SyncStatus_Conflict) : orElse(),
      SyncStatus_Error() =>
        error != null ? error(this as SyncStatus_Error) : orElse(),
      SyncStatus_Ignored() =>
        ignored != null ? ignored(this as SyncStatus_Ignored) : orElse(),
    };
  }
}

/// @nodoc
class SyncStatus_Synced extends SyncStatus {
  const SyncStatus_Synced() : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SyncStatus_Synced;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SyncStatus.synced()';
}

/// @nodoc
class SyncStatus_Pending extends SyncStatus {
  const SyncStatus_Pending() : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SyncStatus_Pending;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SyncStatus.pending()';
}

/// @nodoc
class SyncStatus_Syncing extends SyncStatus {
  const SyncStatus_Syncing() : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SyncStatus_Syncing;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SyncStatus.syncing()';
}

/// @nodoc
class SyncStatus_Conflict extends SyncStatus {
  const SyncStatus_Conflict(this.field0) : super._();

  final ConflictInfo field0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStatus_Conflict && other.field0 == field0);

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() => 'SyncStatus.conflict(field0: $field0)';
}

/// @nodoc
class SyncStatus_Error extends SyncStatus {
  const SyncStatus_Error(this.field0) : super._();

  final String field0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStatus_Error && other.field0 == field0);

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() => 'SyncStatus.error(field0: $field0)';
}

/// @nodoc
class SyncStatus_Ignored extends SyncStatus {
  const SyncStatus_Ignored() : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SyncStatus_Ignored;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SyncStatus.ignored()';
}

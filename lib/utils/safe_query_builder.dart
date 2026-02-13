import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SafeQueryBuilder {
  const SafeQueryBuilder._();

  static Query<T> safeWhere<T>(
    Query<T> query,
    Object? field,
    dynamic value, {
    Type? expectedType,
  }) {
    final isInvalidField =
        field == null || (field is String && field.trim().isEmpty);
    if (isInvalidField) {
      debugPrint('FIRESTORE QUERY ERROR -> where field is null/empty');
      return query;
    }
    if (value == null) return query;
    if (value is String && value.trim().isEmpty) return query;

    if (expectedType != null && !_isExpectedType(value, expectedType)) {
      debugPrint(
        'FIRESTORE QUERY ERROR -> type mismatch for "$field": expected $expectedType, got ${value.runtimeType}',
      );
      return query;
    }

    return query.where(field, isEqualTo: value);
  }

  static Query<T> safeWhereIn<T>(
    Query<T> query,
    Object? field,
    List<dynamic>? values,
  ) {
    final isInvalidField =
        field == null || (field is String && field.trim().isEmpty);
    if (isInvalidField) {
      debugPrint('FIRESTORE QUERY ERROR -> whereIn field is null/empty');
      return query;
    }
    if (values == null || values.isEmpty) {
      return query;
    }
    return query.where(field, whereIn: values);
  }

  static Query<T> safeArrayContainsAny<T>(
    Query<T> query,
    Object? field,
    List<dynamic>? values,
  ) {
    final isInvalidField =
        field == null || (field is String && field.trim().isEmpty);
    if (isInvalidField) {
      debugPrint('FIRESTORE QUERY ERROR -> arrayContainsAny field is null/empty');
      return query;
    }
    if (values == null || values.isEmpty) {
      debugPrint('FIRESTORE QUERY ERROR -> arrayContainsAny list is empty');
      return query;
    }
    return query.where(field, arrayContainsAny: values);
  }

  static Query<T> safeOrderBy<T>(
    Query<T> query,
    Object? field, {
    bool descending = false,
  }) {
    final isInvalidField =
        field == null || (field is String && field.trim().isEmpty);
    if (isInvalidField) {
      debugPrint('FIRESTORE QUERY ERROR -> orderBy field is null/empty');
      return query;
    }
    return query.orderBy(field, descending: descending);
  }

  static bool _isExpectedType(dynamic value, Type expectedType) {
    if (expectedType == String) return value is String;
    if (expectedType == int) return value is int;
    if (expectedType == double) return value is double;
    if (expectedType == bool) return value is bool;
    if (expectedType == List) return value is List;
    if (expectedType == Map) return value is Map;
    return true;
  }
}

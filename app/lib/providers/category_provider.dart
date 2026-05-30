import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/managed_category.dart';
import 'auth_provider.dart';

class CategoryQuery {
  const CategoryQuery({
    this.scope = 'Personal',
    this.familySpaceId,
    this.includeArchived = false,
  });

  final String scope;
  final String? familySpaceId;
  final bool includeArchived;

  @override
  bool operator ==(Object other) {
    return other is CategoryQuery &&
        other.scope == scope &&
        other.familySpaceId == familySpaceId &&
        other.includeArchived == includeArchived;
  }

  @override
  int get hashCode => Object.hash(scope, familySpaceId, includeArchived);
}

final managedCategoriesProvider =
    FutureProvider.family<List<ManagedCategory>, CategoryQuery>(
  (ref, query) async {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) return const [];
    final dio = ref.watch(dioProvider);
    final response = await dio.get(
      ApiConstants.categories,
      queryParameters: {
        'scope': query.scope,
        'includeArchived': query.includeArchived,
        if (query.familySpaceId != null) 'familySpaceId': query.familySpaceId,
      },
    );

    final data = response.data as List<dynamic>? ?? [];
    return data
        .map((item) =>
            ManagedCategory.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  },
);

final categoryActionsProvider = Provider<CategoryActions>((ref) {
  return CategoryActions(ref);
});

class CategoryActions {
  CategoryActions([this._ref]);

  final Ref? _ref;

  Ref get _requireRef {
    final ref = _ref;
    if (ref == null) {
      throw StateError('CategoryActions requires a Riverpod ref.');
    }
    return ref;
  }

  Future<ManagedCategory> create({
    required String name,
    required String type,
    String scope = 'Personal',
    String? familySpaceId,
    String? iconKey,
    String? colorKey,
  }) async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    final response = await dio.post(
      ApiConstants.categories,
      data: {
        'name': name,
        'type': type,
        'scope': scope,
        if (familySpaceId != null) 'familySpaceId': familySpaceId,
        if (iconKey != null) 'iconKey': iconKey,
        if (colorKey != null) 'colorKey': colorKey,
      },
    );

    ref.invalidate(managedCategoriesProvider);
    return ManagedCategory.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<ManagedCategory> update({
    required String id,
    String? name,
    String? iconKey,
    String? colorKey,
    bool? isArchived,
  }) async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    final response = await dio.put(
      ApiConstants.category(id),
      data: {
        if (name != null) 'name': name,
        if (iconKey != null) 'iconKey': iconKey,
        if (colorKey != null) 'colorKey': colorKey,
        if (isArchived != null) 'isArchived': isArchived,
      },
    );

    ref.invalidate(managedCategoriesProvider);
    return ManagedCategory.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> archive(String id) async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    await dio.delete(ApiConstants.category(id));
    ref.invalidate(managedCategoriesProvider);
  }
}

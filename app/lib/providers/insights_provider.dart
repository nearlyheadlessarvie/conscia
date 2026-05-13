import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/insights_models.dart';
import 'auth_provider.dart';
import 'transaction_providers.dart';

final insightsSummaryProvider = FutureProvider<InsightsSummary?>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return null;
  ref.watch(transactionListProvider);
  try {
    final dio = ref.watch(dioProvider);
    final response =
        await dio.get<Map<String, dynamic>>(ApiConstants.insightsSummary);
    if (response.data == null) return null;
    return InsightsSummary.fromJson(response.data!);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    return null;
  }
});

final insightsMerchantsProvider =
    FutureProvider<List<MerchantStat>>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return const [];
  try {
    final dio = ref.watch(dioProvider);
    final response =
        await dio.get<List<dynamic>>(ApiConstants.insightsMerchants);
    return (response.data ?? [])
        .map((e) => MerchantStat.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException {
    return [];
  }
});

final insightsCategoriesProvider =
    FutureProvider<List<CategoryStat>>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return const [];
  try {
    final dio = ref.watch(dioProvider);
    final response =
        await dio.get<List<dynamic>>(ApiConstants.insightsCategories);
    return (response.data ?? [])
        .map((e) => CategoryStat.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException {
    return [];
  }
});

final merchantDetailProvider =
    FutureProvider.family<MerchantDetail?, String>((ref, merchant) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return null;
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(
        ApiConstants.insightsMerchantDetail(merchant));
    if (response.data == null) return null;
    return MerchantDetail.fromJson(response.data!);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    return null;
  }
});

final categoryDetailProvider =
    FutureProvider.family<CategoryDetail?, String>((ref, category) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return null;
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(
        ApiConstants.insightsCategoryDetail(category));
    if (response.data == null) return null;
    return CategoryDetail.fromJson(response.data!);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    return null;
  }
});

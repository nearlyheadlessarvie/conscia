import 'dart:async';
import 'dart:convert';

import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UserProfile parses profile picture key and photo url', () {
    final profile = UserProfile.fromJson({
      'id': 'user-1',
      'email': 'story@example.com',
      'displayName': 'Story Demo',
      'profilePictureKey': 'profile-pictures/user-1/avatar.jpg',
      'photoUrl': 'https://cdn.example.com/avatar.jpg',
      'preferredCurrency': 'PHP',
      'locale': 'en_PH',
      'createdAt': '2026-05-15T00:00:00Z',
      'hasCompletedOnboarding': true,
    });

    expect(profile.displayName, 'Story Demo');
    expect(profile.profilePictureKey, 'profile-pictures/user-1/avatar.jpg');
    expect(profile.photoUrl, 'https://cdn.example.com/avatar.jpg');
  });

  test('updateProfile sends display name and profile picture key', () async {
    final adapter = _RecordingAdapter((options, bytes) {
      expect(options.method, 'PUT');
      expect(options.path, 'users/me');
      final body = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      expect(body['displayName'], 'Story Demo');
      expect(body['profilePictureKey'], 'profile-pictures/user-1/avatar.jpg');

      return ResponseBody.fromString(
        jsonEncode({
          'id': 'user-1',
          'email': 'story@example.com',
          'displayName': 'Story Demo',
          'profilePictureKey': 'profile-pictures/user-1/avatar.jpg',
          'photoUrl': 'https://cdn.example.com/avatar.jpg',
          'preferredCurrency': 'PHP',
          'locale': 'en_PH',
          'createdAt': '2026-05-15T00:00:00Z',
          'hasCompletedOnboarding': true,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/'))
      ..httpClientAdapter = adapter;

    final profile = await UserService(dio).updateProfile(
      displayName: 'Story Demo',
      profilePictureKey: 'profile-pictures/user-1/avatar.jpg',
    );

    expect(profile.profilePictureKey, 'profile-pictures/user-1/avatar.jpg');
    expect(profile.photoUrl, 'https://cdn.example.com/avatar.jpg');
  });

  test('createProfilePictureUpload returns presigned upload data', () async {
    final adapter = _RecordingAdapter((options, bytes) {
      expect(options.method, 'POST');
      expect(options.path, 'users/me/profile-picture-upload-url');
      final body = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      expect(body['contentType'], 'image/jpeg');

      return ResponseBody.fromString(
        jsonEncode({
          'uploadUrl': 'https://s3.example.com/upload',
          'proxyUploadUrl': 'users/me/profile-picture-upload?key=profile-pictures%2Fuser-1%2Favatar.jpg',
          'profilePictureKey': 'profile-pictures/user-1/avatar.jpg',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/'))
      ..httpClientAdapter = adapter;

    final upload = await UserService(dio).createProfilePictureUpload(
      contentType: 'image/jpeg',
    );

    expect(upload.uploadUrl, 'https://s3.example.com/upload');
    expect(
      upload.proxyUploadUrl,
      'users/me/profile-picture-upload?key=profile-pictures%2Fuser-1%2Favatar.jpg',
    );
    expect(upload.profilePictureKey, 'profile-pictures/user-1/avatar.jpg');
  });

  test('uploadProfilePicture sends raw bytes to the presigned url', () async {
    final uploadAdapter = _RecordingAdapter((options, bytes) {
      expect(options.method, 'PUT');
      expect(options.uri.toString(), 'https://s3.example.com/upload');
      expect(options.headers[Headers.contentTypeHeader], 'image/jpeg');
      expect(bytes, [1, 2, 3, 4]);

      return ResponseBody.fromString('', 200);
    });
    final uploadDio = Dio()..httpClientAdapter = uploadAdapter;

    await UserService(
      Dio(BaseOptions(baseUrl: 'https://api.example.com/api/')),
      uploadDio: uploadDio,
    ).uploadProfilePicture(
      uploadUrl: 'https://s3.example.com/upload',
      bytes: [1, 2, 3, 4],
      contentType: 'image/jpeg',
    );

    expect(uploadAdapter.requestCount, 1);
  });

  test('uploadProfilePicture prefers same-origin api proxy when present',
      () async {
    final apiAdapter = _RecordingAdapter((options, bytes) {
      expect(options.method, 'PUT');
      expect(
        options.path,
        'users/me/profile-picture-upload?key=profile-pictures%2Fuser-1%2Favatar.jpg',
      );
      expect(options.headers[Headers.contentTypeHeader], 'image/png');
      expect(bytes, [5, 6, 7, 8]);

      return ResponseBody.fromString('', 204);
    });
    final uploadAdapter = _RecordingAdapter((_, __) {
      fail('Direct S3 upload should not be used when proxyUploadUrl is present');
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/'))
      ..httpClientAdapter = apiAdapter;
    final uploadDio = Dio()..httpClientAdapter = uploadAdapter;

    await UserService(dio, uploadDio: uploadDio).uploadProfilePicture(
      uploadUrl: 'http://localhost:9000/conscia-receipts/avatar.jpg',
      proxyUploadUrl:
          'users/me/profile-picture-upload?key=profile-pictures%2Fuser-1%2Favatar.jpg',
      bytes: [5, 6, 7, 8],
      contentType: 'image/png',
    );

    expect(apiAdapter.requestCount, 1);
    expect(uploadAdapter.requestCount, 0);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._handler);

  final ResponseBody Function(RequestOptions options, List<int> bytes) _handler;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount += 1;
    final bytes = requestStream == null
        ? <int>[]
        : await requestStream.expand((chunk) => chunk).toList();
    return _handler(options, bytes);
  }

  @override
  void close({bool force = false}) {}
}

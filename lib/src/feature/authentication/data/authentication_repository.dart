import 'dart:async';
import 'package:teledesk/src/common/util/api_client.dart';
import 'package:teledesk/src/feature/authentication/model/sign_in_data.dart';
import 'package:teledesk/src/feature/authentication/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class IAuthenticationRepository {
  Future<User> signIn(SignInData data);
}

class AuthenticationRepositoryImpl implements IAuthenticationRepository {
  AuthenticationRepositoryImpl({
    required final SharedPreferences sharedPreferences,
    required final ApiClient apiClient,
  }) : _sharedPreferences = sharedPreferences,
       _apiClient = apiClient;

  final SharedPreferences _sharedPreferences;
  final ApiClient _apiClient;

  @override
  Future<User> signIn(SignInData data) {
    throw UnimplementedError();
  }
}

class AuthenticationRepositoryFake implements IAuthenticationRepository {
  @override
  Future<User> signIn(SignInData data) async => User.defaultUser();
}

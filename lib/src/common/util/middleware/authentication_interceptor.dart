import 'package:teledesk/src/common/util/api_client.dart';
import 'package:l/l.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationInterceptor {
  AuthenticationInterceptor({required final AuthenticationHeaders authenticationHeaders})
    : _authenticationHeaders = authenticationHeaders;

  final AuthenticationHeaders _authenticationHeaders;

  ApiClientHandler call(ApiClientHandler innerHandler) => (request, context) async {
    final headers = _authenticationHeaders.headers();
    if (headers.isNotEmpty) {
      request.headers.addAll(headers);
    }

    final response = await innerHandler(request, context);

    return response;
  };
}

class AuthenticationHeaders {
  const AuthenticationHeaders({required final SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  final SharedPreferences _sharedPreferences;

  Map<String, String> headers() {
    final headers = <String, String>{};
    final token = _sharedPreferences.getString('token');
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    l.d('Request sending headers: $headers');

    return headers;
  }
}

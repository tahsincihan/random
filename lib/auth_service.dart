import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String authTokenUrl = 'https://mapyourevent.myeenterprises.co.uk/oauth/token';
  static const String clientId = '2';
  static const String clientSecret = 'qooYBzdaTJ4AFllFd1KNPFeiWsku7ns1QGvXx5RX';
  static const String grantType = 'password';
  static const String scope = '*';

  /// Attempts to log in the user using the provided username and password.
  /// On success, returns the decoded JSON response containing the access token.
  /// Throws an exception if the login fails.
  Future<Map<String, dynamic>> login(String username, String password) async {
    final Map<String, dynamic> payload = {
      'grant_type': grantType,
      'client_id': clientId,
      'client_secret': clientSecret,
      'username': username,
      'password': password,
      'scope': scope,
    };

    final response = await http.post(
      Uri.parse(authTokenUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Incorrect email or password! Try Again ${response.statusCode}');
    }
  }

}
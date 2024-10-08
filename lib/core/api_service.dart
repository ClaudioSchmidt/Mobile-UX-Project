import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'token_storage.dart';

class ApiService {
  Future<String?> login(String userId, String password) async {
    final response = await http.get(
      Uri.parse('$apiUrl?request=login&userid=$userId&password=$password'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['token'];
    } else {
      return null;
    }
  }

  Future<void> logout() async {
    final tokenStorage = TokenStorage();
    await tokenStorage.deleteToken();
    }

  Future<String?> register(String userId, String password, String fullName, String nickname) async {
    final response = await http.get(
      Uri.parse('$apiUrl?request=register&userid=$userId&password=$password&fullname=$fullName&nickname=$nickname'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['token'];
    } else {
      return null;
    }
  }

  Future<bool> deregister(String userId) async {
    final tokenStorage = TokenStorage();
    String? token = await tokenStorage.getToken();  // Token holen

    if (token == null) {
      return false;  // Wenn kein Token existiert, abbrechen
    }

    final response = await http.delete(
      Uri.parse('$apiUrl?request=deregister&userid=$userId&token=$token'),
      headers: {
        'Authorization': 'Bearer $token',  // Token im Header senden
      },
    );

    if (response.statusCode == 200) {
      await tokenStorage.deleteToken();  // Lösche den Token lokal
      return true;
    } else {
      return false;
    }
  }
}

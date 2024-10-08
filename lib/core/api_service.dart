import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

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
}

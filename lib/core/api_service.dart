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

    Future<List<String>?> getMessages(String token, {int chatId = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl?request=getmessages&token=$token&chatid=$chatId'),
      );

      print('Get Messages Response: ${response.body}');

      
      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((message) => message['text'].toString()).toList();
      } else {
        print('Get Messages failed with status: ${response.statusCode}');
        return null;
      }
    

    } catch (e) {
      print('Error getting Messages: $e');
      return null;
    }
  }

 Future<bool> postMessage(String token, String text, {int chatId = 0}) async {
  try {
    final response = await http.post(
      Uri.parse('$apiUrl'), 
      body: {
        'request': 'postmessage', 
        'token': token,         
        'text': text,            
        'chatid': chatId.toString(),
      },
    );

    print('Post Message Response: ${response.body}'); 

    return response.statusCode == 200;
  } catch (e) {
    print('Error sending message: $e');
    return false;
  }
}

}

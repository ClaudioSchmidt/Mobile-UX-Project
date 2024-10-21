import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart'; // Ensure constants.dart defines 'apiUrl'
import 'token_storage.dart'; // Ensure token_storage.dart manages token retrieval and storage

class ApiService {
  final http.Client httpClient;

  ApiService({http.Client? httpClient}) : httpClient = httpClient ?? http.Client();

  Future<String?> login(String userId, String password) async {
    final uri = Uri.parse('$apiUrl?request=login&userid=$userId&password=$password');
    try {
      final response = await httpClient.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['token'];
      }
      return null;
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final tokenStorage = TokenStorage();
      final token = await tokenStorage.getToken();
      if (token == null) return;

      final uri = Uri.parse('$apiUrl?request=logout&token=$token');
      final response = await httpClient.get(uri);

      if (response.statusCode == 200) {
        await tokenStorage.deleteToken();
      } else {
        throw Exception('Logout failed');
      }
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<String?> register(String userId, String password, String fullName, String nickname) async {
    final uri = Uri.parse('$apiUrl?request=register&userid=$userId&password=$password&fullname=$fullName&nickname=$nickname');
    try {
      final response = await httpClient.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['token'];
      }
      return null;
    } catch (e) {
      print('Error during registration: $e');
      return null;
    }
  }

  Future<bool> deregister() async {
    try {
      final tokenStorage = TokenStorage();
      final token = await tokenStorage.getToken();
      if (token == null) return false;

      final uri = Uri.parse('$apiUrl?request=deregister&token=$token');
      final response = await httpClient.get(uri);

      if (response.statusCode == 200) {
        await tokenStorage.deleteToken();
        return true;
      }
      return false;
    } catch (e) {
      print('Error during deregistration: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getChats(String token) async {
    final uri = Uri.parse('$apiUrl?request=getchats&token=$token');
    try {
      final response = await httpClient.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json.containsKey('chats')) {
          return List<Map<String, dynamic>>.from(json['chats']);
        }
        print('No chats found in the response.');
        return null;
      }
      print('Failed to fetch chats: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error fetching chats: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getMessages(String token, {required int chatId}) async {
    final uri = Uri.parse('$apiUrl?request=getmessages&token=$token&chatid=$chatId');
    try {
      final response = await httpClient.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json.containsKey('messages')) {
          //print('Response body: ${List<Map<String, dynamic>>.from(json['messages'])}');
          return List<Map<String, dynamic>>.from(json['messages']);
        }
        print('No messages found in the response.');
        return null;
      }
      print('Failed to fetch messages: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error fetching messages: $e');
      return null;
    }
  }

    Future<bool> createChat(String token, String chatName) async {
    final uri = Uri.parse('$apiUrl');
    final body = {
      'request': 'createchat',
      'token': token,
      'chatname': chatName,
    };

    try {
      final response = await httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      print('Create Chat Response Status Code: ${response.statusCode}');
      print('Create Chat Response Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error creating chat: $e');
      return false;
    }
  }

/* -> complain message
Future<bool> postMessage(String token, String text, {required int chatId}) async {
  final uri = Uri.parse('$apiUrl');
  final body = {
    'request': 'postmessage',
    'token': token,
    'text': text,
    'chatid': chatId.toString(),
  };

  try {
    final response = await httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    print('Post Message Response Status Code: ${response.statusCode}');
    print('Post Message Response Body: ${response.body}');

    return response.statusCode == 200;
  } catch (e) {
    print('Error posting message: $e');
    return false;
  }
}
*/

/* -> <e test
Future<bool> postMessage(String token, String text, {required int chatId}) async {
  final uri = Uri.parse('$apiUrl');
  final body = jsonEncode({
    'request': 'postmessage',
    'token': token,
    'text': text,
    'chatid': chatId.toString(),
  });

  try {
    final response = await httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json', // Setze den Content-Type auf JSON
      },
      body: body,
    );

    print('Post Message Response Status Code: ${response.statusCode}');
    print('Post Message Response Body: ${response.body}');

    // Prüfe, ob die Antwort wirklich ein JSON ist und ob sie die erwarteten Daten enthält
    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body);
        return json.containsKey('message-id'); // Überprüfe, ob die Antwort das erwartete Feld enthält
      } catch (e) {
        print('Error parsing JSON: $e');
        return false;
      }
    } else {
      return false;
    }
  } catch (e) {
    print('Error posting message: $e');
    return false;
  }
}
*/

/* -> test part 2
Future<bool> postMessage(String token, String text, {required int chatId}) async {
  final uri = Uri.parse('$apiUrl');
  final body = {
    'request': 'postmessage',
    'token': token,
    'text': text,
    'chatid': chatId.toString(),
  };

  try {
    final response = await httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    print('Post Message Response Status Code: ${response.statusCode}');
    print('Post Message Response Body: ${response.body}');

    return response.statusCode == 200;
  } catch (e) {
    print('Error posting message: $e');
    return false;
  }
}
*/

// -> test part 3, just to be sure
Future<bool> postMessage(String token, String text, {required int chatId}) async {
  final uri = Uri.parse('$apiUrl');
  final body = jsonEncode({
    'request': 'postmessage',
    'token': token,
    'text': text,
    'chatid': chatId.toString(),
  });

  try {
    final response = await httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json', // Setze den Content-Type auf JSON
      },
      body: body,
    );

    print('Post Message Response Status Code: ${response.statusCode}');
    print('Post Message Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // Überprüfe, ob der Status und der Code in der Antwort "ok" und 200 sind
      if (json['status'] == 'ok' && json['code'] == 200) {
        return true;
      }
    }
    return false;
  } catch (e) {
    print('Error posting message: $e');
    return false;
  }
}

}

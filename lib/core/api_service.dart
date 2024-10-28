import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart'; // Ensure constants.dart defines 'apiUrl'
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> updateToken(String? token) async {
    if (token != null) {
      await _storage.write(key: 'token', value: token);
      print("Token wurde erfolgreich aktualisiert.");
    } else {
      await _storage.delete(key: 'token');
      print("Token wurde erfolgreich gelöscht.");
    }
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: 'token');
    print("Aktueller Token: $token");
    return token;
  }

  Future<void> clearAllStorage() async {
    await _storage.deleteAll();
    print("Alle gespeicherten Daten wurden vollständig gelöscht.");
  }

  Future<String?> register(String userId, String password, String nickname, String fullName) async {
    await clearAllStorage(); // Clear old data
    final response = await http.get(
      Uri.parse('$apiUrl?request=register&userid=$userId&password=$password&nickname=$nickname&fullname=$fullName'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      await updateToken(token);
      return token;
    }
    return null;
  }

  Future<String?> login(String userId, String password) async {
    await clearAllStorage(); // Clear old data

    final response = await http.get(
      Uri.parse('$apiUrl?request=login&userid=$userId&password=$password'),
    );

    if (response.statusCode == 200) {
      print(response.body);
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok' && data.containsKey('token')) {
        final token = data['token'];
        await updateToken(token);
        print("Login erfolgreich, Token erhalten und gespeichert: $token");
        return token;
      } else {
        print("Login fehlgeschlagen: ${data['message']}");
      }
    } else {
      print("Fehler beim Login: Statuscode ${response.statusCode}");
    }
    return null;
  }

  Future<bool> logout() async {
    final token = await getToken();
    if (token == null) {
      print("Benutzer ist bereits ausgeloggt oder kein Token vorhanden.");
      return true;
    }

    final response = await http.get(
      Uri.parse('$apiUrl?request=logout&token=$token'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        await clearAllStorage();
        print("Logout erfolgreich und alle Daten gelöscht.");
        return true;
      } else {
        print("Logout fehlgeschlagen: ${data['message']}");
      }
    } else {
      print("Fehler beim Logout: Statuscode ${response.statusCode}");
    }
    return false;
  }

  Future<bool> deregister() async {
    final token = await getToken();
    if (token == null) {
      print("Fehler: Kein gültiger Token für die Deregistrierung gefunden.");
      return false;
    }

    final response = await http.get(
      Uri.parse('$apiUrl?request=deregister&token=$token'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        await clearAllStorage();
        print("Account erfolgreich gelöscht und alle Daten zurückgesetzt.");
        return true;
      } else {
        print("Fehler beim Löschen des Accounts: ${data['message']}");
      }
    } else {
      print("Serverfehler bei der Deregistrierung: ${response.statusCode}");
    }
    return false;
  }

  Future<List<dynamic>?> getChats() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$apiUrl?request=getchats&token=$token'),
    );

    if (response.statusCode == 200) {
      print('getChats Response body: ${response.body}');
      final responseBody = response.body;
      final jsonString = responseBody.substring(responseBody.indexOf('{'));

      final data = jsonDecode(jsonString);
      if (data['status'] == 'ok' && data.containsKey('chats')) {
        return data['chats'];
      }
    }
    return null;
  }

  Future<bool> deleteChat(int chatId) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.get(
      Uri.parse('$apiUrl?request=deletechat&token=$token&chatid=$chatId'),
    );

    if (response.statusCode == 200) {
      print('deleteChat Response body: ${response.body}');
      final data = jsonDecode(response.body);
      return data['status'] == 'ok';
    }
    return false;
  }

  Future<bool> createChat(String chatName) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.get(
      Uri.parse('$apiUrl?request=createchat&token=$token&chatname=$chatName'),
    );

    if (response.statusCode == 200) {
      print('createChat Response body: ${response.body}');
      final data = jsonDecode(response.body);
      return data['status'] == 'ok';
    }
    return false;
  }

  Future<List<dynamic>?> getMessages(int chatId) async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$apiUrl?request=getmessages&token=$token&chatid=$chatId'),
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;
      final jsonString = responseBody.substring(responseBody.indexOf('{'));
      final data = jsonDecode(jsonString);

      if (data['status'] == 'ok' && data.containsKey('messages')) {
        return data['messages']
            .map((message) => {
                  'id': message['id'],
                  'userid': message['userid'] ?? '',
                  'time': message['time'] ?? '',
                  'chatid': message['chatid'] ?? 0,
                  'text': message['text'] ?? '',
                  'usernick': message['usernick'] ?? '',
                  'userhash': message['userhash'] ?? '',
                })
            .toList();
      }
    }
    return null;
  }

  Future<bool> sendMessage(int chatId, String message) async {
    final token = await getToken();
    if (token == null) {
      print("Fehler: Token ist null");
      return false;
    }

    final response = await http.post(
      Uri.parse('$apiUrl'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'request': 'postmessage',
        'token': token,
        'text': message,
        'chatid': chatId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'ok';
    } else {
      print("Fehler: Server antwortete mit Statuscode ${response.statusCode}");
      print("Antwortinhalt: ${response.body}");
      return false;
    }
  }
}

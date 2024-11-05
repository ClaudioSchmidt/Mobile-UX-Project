import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<String?> getUserHash() async {
    return await _storage.read(key: 'userHash');
  }

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
  }

  Future<String?> register(String userId, String password, String nickname, String fullName) async {
    await clearAllStorage();
    final response = await http.get(
      Uri.parse('$apiUrl?request=register&userid=$userId&password=$password&nickname=$nickname&fullname=$fullName&${_generateRandomQuery()}'),
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
  final response = await http.get(
    Uri.parse('$apiUrl?request=login&userid=$userId&password=$password&${_generateRandomQuery()}'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 'ok' && data.containsKey('token') && data.containsKey('hash')) {
      final token = data['token'];
      final userHash = data['hash'];

      await updateToken(token);
      await _storage.write(key: 'userHash', value: userHash);
      
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

    final response = await http.get(
      Uri.parse('$apiUrl?request=logout&token=$token&${_generateRandomQuery()}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        await clearAllStorage();
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

    final response = await http.get(
      Uri.parse('$apiUrl?request=deregister&token=$token&${_generateRandomQuery()}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        await clearAllStorage();
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

    final response = await http.get(
      Uri.parse('$apiUrl?request=getchats&token=$token&${_generateRandomQuery()}'),
    );

    if (response.statusCode == 200) {
      //print('getChats Response body: ${response.body}');
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

    final response = await http.get(
      Uri.parse('$apiUrl?request=deletechat&token=$token&chatid=$chatId&${_generateRandomQuery()}'),
    );

    if (response.statusCode == 200) {
      //print('deleteChat Response body: ${response.body}');
      final data = jsonDecode(response.body);
      return data['status'] == 'ok';
    }
    return false;
  }

  Future<bool> createChat(String chatName) async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$apiUrl?request=createchat&token=$token&chatname=$chatName&${_generateRandomQuery()}'),
    );

    if (response.statusCode == 200) {
      //print('createChat Response body: ${response.body}');
      final data = jsonDecode(response.body);
      return data['status'] == 'ok';
    }
    return false;
  }

  Future<bool> leaveChat(int chatId) async {
  final token = await getToken();

  if (token == null) {
    print("Token ist nicht verfügbar.");
    return false;
  }

  final response = await http.get(
    Uri.parse('$apiUrl?request=leavechat&token=$token&chatid=$chatId&${_generateRandomQuery()}'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 'ok') {
      return true;  // Erfolg wird zurückgegeben
    } else {
      print("Fehler beim Austreten aus dem Chat: ${data['message']}");
    }
  } else {
    print("Serverfehler beim Austreten aus dem Chat: Statuscode ${response.statusCode}");
  }
  return false;
}

Future<bool> joinChat(int chatId) async {
  final token = await getToken();

  if (token == null) {
    print("Token ist nicht verfügbar, kann nicht dem Chat beitreten.");
    return false;
  }

  final uri = Uri.parse('$apiUrl?request=joinchat&token=$token&chatid=$chatId&${_generateRandomQuery()}');
  print("Final URI: $uri");  // Debugging: Ausgabe der finalen URL

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // Debugging: Ausgabe der Serverantwort
      print('Join Chat Response Body: ${response.body}');
      final data = jsonDecode(response.body);
      return data['status'] == 'ok';
    } else {
      print("Serverfehler beim Beitritt zum Chat: Statuscode ${response.statusCode}");
    }
  } catch (e) {
    print("Fehler bei der GET-Anfrage: $e");
  }

  return false;
}

String _generateRandomQuery() {
  return 'random=${DateTime.now().millisecondsSinceEpoch}';
}

Future<List<dynamic>?> getMessages(int chatId, {int? fromId}) async {
  final token = await getToken();
  if (token == null) return null;

  final url = Uri.parse(
    '$apiUrl?request=getmessages&token=$token&chatid=$chatId&${_generateRandomQuery()}${fromId != null ? '&fromid=$fromId' : ''}',
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    //print('getMessages Response body: ${response.body}');
    final responseBody = response.body;
    final jsonString = responseBody.substring(responseBody.indexOf('{'));

    try {
      final data = jsonDecode(jsonString);
      if (data['status'] == 'ok' && data.containsKey('messages')) {
        return data['messages'];
      }
    } catch (e) {
      print("JSON Parsing Error: $e");
    }
  }
  return null;
}

  Future<bool> sendMessage(int chatId, String message) async {
    final token = await getToken();

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
        'random': DateTime.now().millisecondsSinceEpoch,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'ok';
    }
    return false;
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Utility Methods
  Future<void> clearAllStorage() async {
    await _storage.deleteAll();
  }

  Future<String?> getUserHash() async {
    return await _storage.read(key: 'userHash');
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: 'token');
    print("Aktueller Token: $token");
    return token;
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

  String _generateRandomQuery() {
    return 'random=${DateTime.now().millisecondsSinceEpoch}';
  }

  // Authentication Methods
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

  // Chat Management Methods
  Future<List<dynamic>?> getChats() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$apiUrl?request=getchats&token=$token&${_generateRandomQuery()}'),
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;
      final jsonString = responseBody.substring(responseBody.indexOf('{'));
      final data = jsonDecode(jsonString);
      if (data['status'] == 'ok' && data.containsKey('chats')) {
        return data['chats'];
      }
    }
    return null;
  }

  Future<bool> createChat(String chatName) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$apiUrl?request=createchat&token=$token&chatname=$chatName&${_generateRandomQuery()}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'ok';
    }
    return false;
  }

  Future<bool> deleteChat(int chatId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$apiUrl?request=deletechat&token=$token&chatid=$chatId&${_generateRandomQuery()}'),
    );

    if (response.statusCode == 200) {
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
        return true;
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

    final response = await http.get(
      Uri.parse('$apiUrl?request=joinchat&token=$token&chatid=$chatId&${_generateRandomQuery()}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'ok';
    } else {
      print("Serverfehler beim Beitritt zum Chat: Statuscode ${response.statusCode}");
    }
    return false;
  }

  // User and Profile Methods
  Future<List<dynamic>?> getProfiles() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$apiUrl?request=getprofiles&token=$token&${_generateRandomQuery()}'),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        return data['profiles'] ?? [];
      } catch (e) {
        print('Error parsing profiles: $e');
      }
    } else {
      print('Failed to load profiles: ${response.statusCode}');
    }
    return null;
  }

  Future<bool> inviteUserToChat(int chatId, String invitedHash) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$apiUrl?request=invite&token=$token&chatid=$chatId&invitedhash=$invitedHash&${_generateRandomQuery()}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'ok';
    } else {
      print('Failed to invite user: ${response.statusCode}');
    }
    return false;
  }

  // Messaging Methods
  Future<List<dynamic>?> getMessages(int chatId, {int? fromId}) async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$apiUrl?request=getmessages&token=$token&chatid=$chatId${fromId != null ? '&fromid=$fromId' : ''}&${_generateRandomQuery()}'),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok' && data.containsKey('messages')) {
          final messages = data['messages'];
          for (var message in messages) {
            if (message.containsKey('photoid') && message['photoid'] != null) {
              final photoData = await getPhoto(message['photoid']);
              if (photoData != null) {
                message['photoData'] = photoData;
              }
            }
          }
          return messages;
        }
      } catch (e) {
        print("JSON Parsing Error in getMessages: $e");
      }
    } else {
      print('Failed to get messages, Status Code: ${response.statusCode}');
    }
    return null;
  }

  Future<Uint8List?> getPhoto(String photoId) async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$apiUrl?request=getphoto&token=$token&photoid=$photoId'),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      print('Failed to get photo with ID: $photoId, Status Code: ${response.statusCode}');
    }
    return null;
  }

  Future<bool> sendMessage({
    required int chatId,
    String? text,
    String? base64Image,
  }) async {
    final token = await getToken();
    final body = {
      'request': 'postmessage',
      'token': token,
      'chatid': chatId,
      if (text != null && text.isNotEmpty) 'text': text,
      if (base64Image != null) 'photo': base64Image,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'ok';
    }
    print('API Error: ${response.statusCode}, ${response.body}');
    return false;
  }
}

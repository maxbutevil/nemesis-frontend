

import "package:firebase_core/firebase_core.dart";
import 'package:firebase_storage/firebase_storage.dart';
import "package:firebase_auth/firebase_auth.dart";
import "package:google_sign_in/google_sign_in.dart";
import 'package:flutter/foundation.dart';

import "/firebase_options.dart";

import 'utils.dart';

//import 'dart:typed_data';
import 'dart:io';
import "dart:convert";
import 'dart:math' show Random;



import 'user_data.dart';

//import "package:http/http.dart" as http;


//import 'websocket'



//const URL = "http://localhost:5050";
//const root = "10.242.160.187";
//const root = "10.0.0.79";
//const useUrl = true;
const root = "https://nemesis-fetp.onrender.com";
const port = 5050;
const rootUrl = "$root";


final FirebaseStorage storage = FirebaseStorage.instance;
final FirebaseAuth auth = FirebaseAuth.instance;

HttpClient httpClient = HttpClient();
WebSocket? ws;

UserData? userData;

//final matchesChanged = Signal<Map<String, Match>>();
//Map<String, Match>? matches;

final matches = Observable<Map<String, Match>?>(null);


String? getUserId() => auth.currentUser?.uid;
bool isSignedIn() => auth.currentUser != null;

void onAuthStateChanges(Function(bool) callback) {
  auth
    .authStateChanges()
    .listen((User? user) {
      callback(user != null);
    });
}

Future<void> initialize() async {
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  auth
    .authStateChanges()
    .listen((user) {
      if (user == null) {
        userData = null;
        matches.set(null);
        wsClose();
      } else {
        //refreshProfileQueue();
        loadInitialMatchData();
        wsConnect();
      }
    });
  
}
Future<UserCredential?> googleSignIn() async {
  
  try {
    
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    
    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    
    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    
    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
    
  } catch (e) {
    debugPrint("Authentication Error | $e");
    return null;
  }
  
  
}
Future<void> googleSignOut() async {
  await auth.signOut();
}

/* Photos */
Reference get rootRef => storage.ref("profile-photos");
Reference photoRef(ProfilePhoto photo) =>
  rootRef.child(photo.profileID).child(photo.photoID);
Future<Uint8List?> _loadPhotoData(ProfilePhoto photo) async {
  
  try {
    debugPrint("Loading Photo: ${photo.path}");
    return photoRef(photo).getData();
  } catch(err) {
    debugPrint("Error Loading Photo: ${photo.path}");
    return null;
  }
  
}
Future<Uint8List?> getPhotoData(ProfilePhoto photo) async {
  return (photo.data ??= await _loadPhotoData(photo));
}
Future<List<Uint8List?>> getProfilePhotoData(Profile profile) async {
  
  return (await Future.wait(
    profile.photos.map(
      (photo) => getPhotoData(photo)
    )
  ));
  
}

Future<void> uploadPhoto(ProfilePhoto photo) async {
  
  if (isSignedIn() && photo.data != null) {
    
    try {
      await photoRef(photo)
        .putData(photo.data!);
    } catch(err) {
      throw Exception("Error uploading photo: $err");
    }
  } else {
    debugPrint("Attempted unauthorized photo upload: ${photo.path}");
  }
  
}
Future<void> uploadPhotos(Iterable<ProfilePhoto> photos) async {
  if (photos.isEmpty) { return; }
  await Future.wait(photos.map(uploadPhoto));
}
Future<void> deletePhoto(ProfilePhoto photo) async {
  
  try {
    await photoRef(photo).delete(); // ok this is a problem
  } catch(err) {
    throw Exception("Error deleting photo: $err");
  }
  
}
Future<void> deletePhotos(Iterable<ProfilePhoto> photos) async {
  if (photos.isEmpty) { return; }
  await Future.wait(photos.map(deletePhoto));
}



/* User Data */
Future<UserData?> getUserData() async {
  
  if (!isSignedIn()) {
    return null;
  } else if (userData != null) {
    return userData;
  } else {
    return (userData = await readUserData());
  }
  
}
/*
Future<bool> saveUserPhotos({ required Set<ProfilePhoto> oldPhotos }) {
  
  addedPhotos.forEach(uploadPhoto);
  removedPhotos.forEach(deletePhoto);
  
}
*/
Future<bool> saveUserData({ required UserData oldData }) async {
  
  if (!isSignedIn()) {
    return false;
  }
  
  var delta = userData!.deltaMap(oldData);
  debugPrint("UserData delta: $delta");
  
  if (delta.isEmpty) {
    return true; // no changes necessary
  }
  
  var oldPhotos = oldData.photos.toSet();
  var newPhotos = userData!.photos.toSet();
  var addedPhotos = newPhotos.difference(oldPhotos);
  var removedPhotos = oldPhotos.difference(newPhotos);
  
  try {
    
    await Future.wait([
      writeUserData(delta),
      uploadPhotos(addedPhotos)
    ]);
    
    await deletePhotos(removedPhotos);
    
  } catch (err) {
    debugPrint("Error saving user data: $err");
    return false;
  }
  
  //return await writeUserData(delta);
  return true;
  
}


/* Profile Queue */
//Observable<List<ProfileData>> profileQueue = Observable([]);
Signal<ProfileData?> nextProfileChanged = Signal();
List<ProfileData> profileQueue = [];

Future<void> refreshProfileQueue() async {
  
  if (profileQueue.length <= 2) {
    wsRequestQueueRefresh(); // mildly sketchy, can easily duplicate
  }
  
}
void toNextProfile() {
  
  // do this first, so we hopefully successfully blacklist the current profile
  // this is jank
  refreshProfileQueue();
  
  if (profileQueue.isNotEmpty) {
    profileQueue.removeAt(0);
    nextProfileChanged.emit(profileQueue.firstOrNull);
  }
  
}


/* Match/Chat */
void loadInitialMatchData() async {
  
  var data = await getInitialMatchData();
  
  if (data == null) {
    return;
  }
  
  var (profiles, messages) = data;
  handleMatchData(profiles);
  handleMatchMessages(messages.toList().reversed); // clunky
  
}
void handleMatchData(Iterable<ProfileData> profiles) {
  
  matches.data ??= {};
  
  for (var profile in profiles) {
    
    String id = profile.id;
  
    if (matches.data!.containsKey(id)) {
      print("Duplicate match received: $id");
      return;
    }
    
    matches.data![id] = Match(profile);
    
  }
  
  
  
}
void handleMatchMessages(Iterable<ChatMessage> messages, { bool old = false }) {
  
  Map<String, List<ChatMessage>> newMessages = {};
  
  for (var message in messages) {
    newMessages[message.userID] ??= [];
    newMessages[message.userID]!.add(message);
  }
  
  if (matches.data == null) {
    print("Received match messages without initial match data.");
    return;
  }
  
  newMessages.forEach((id, messages) {
    
    if (matches.data!.containsKey(id)) {
      if (old) {
        matches.data![id]!.addOldMessages(messages);
      } else {
        matches.data![id]!.addNewMessages(messages);
      }
      
    } else {
      print("Received message for invalid match: $id");
    }
    
  });
  
}

void handleOutgoingMessage(Match receiver, String content) async {
  
  var userID = receiver.profileData.id;
  
  if (ws != null) {
  
    handleMatchMessages([
      ChatMessage.outgoing(
        id: "",
        userID: userID,
        content: content
      )
    ]);
    
    wsSendChatMessage(userID, content);
  
  }
  
}

/* HTTP */
Future<T?> _request<T>(Future<T> Function(String) callback) async {
  
  String? token = await auth.currentUser!.getIdToken();
  
  if (token == null) {
    debugPrint("Attempted unauthorized HTTP request");
    return null;
  } else {
    String authHeader = "Bearer $token";
    return await callback(authHeader);
  }
  
}
Future<UserData?> readUserData() async {
  
  var response = await _request(
    (String authHeader) async {
      
      //HttpClientRequest request = await httpClient.get(root, port, "/self/read");
      HttpClientRequest request = await httpClient.getUrl(
        Uri.parse("$rootUrl/self/read"));
      
      //await httpClient.getUrl(
        //Uri.parse("https://nemesis-fetp.onrender.com/self/read")); //await httpClient.get(root, port, "/self/read");
      
      /*
      if (useUrl) {
        request = await httpClient.getUrl(Uri.parse("$rootUrl/self/read"));
      } else {
        
      }
      */
      //HttpClientRequest request = await httpClient.get(root, port, "/self/read");
      //HttpClientRequest 
      request.headers.add("Authorization", authHeader);
      return await request.close();
    }
  );
  
  /*var response = await _request(
    (String authHeader) => http.get(
      Uri.parse("$httpRoot/self/read"),
      headers: { "Authorization": authHeader }
    )
  );*/
  
  if (response != null && response.statusCode == 200) {
    String body = await response.transform(utf8.decoder).join();
    print(body);
    return UserData.fromMap(getUserId()!, jsonDecode(body));
    //debugPrint("Retrieved self profile data: ${response.body}");
    //return UserData.fromMap(getUserId()!, jsonDecode(response.body));
  } else {
    throw Exception("Error reading profile");
    //return null;
  }
  
}
Future<bool> writeUserData(Map<String, Object> delta) async {
  
  if (delta.isEmpty) {
    return true;
  }
  
  var response = await _request(
    (String authHeader) async {
      
      //HttpClientRequest request = await httpClient.post(root, port, "/self/write");
      HttpClientRequest request = await httpClient.postUrl(Uri.parse("$root/self/write"));
      /*if (useUrl) {
        request = await httpClient.postUrl(Uri.parse("$rootUrl/self/write"));
      } else {
        request = await httpClient.post(root, port, "/self/write");
      }*/
      //await httpClient.post(root, port, "/self/write");
      request.headers.add("Authorization", authHeader);
      request.headers.add("Content-Type", "application/json");
      request.write(jsonEncode(delta));
      
      return await request.close();
      
    }
  );
  
  /*
  var response = await _request(
    (String authHeader) => http.post(
      Uri.parse("$httpRoot/self/write"),
      headers: {
        "Authorization": authHeader,
        "Content-Type": "application/json",
      },
      body: jsonEncode(delta)
    )
  );
  */
  
  return response != null && response.statusCode == 200;
  
}
/*Future<List<ProfileData>?> getQueueProfiles() async {
  
  var response = await _request(
    (String authHeader) async {
      HttpClientRequest request = await httpClient.get(root, port, "/discover");
      request.headers.add("Authorization", authHeader);
      return await request.close();
    }
  );
  
  if (response != null && response.statusCode == 200) {
    String body = await response.getBody();
    //debugPrint(response.body);
    //debugPrint("${ProfileData.fromMapList(jsonDecode(response.body))}");
    return ProfileData.fromMapList(jsonDecode(body));
  } else {
    throw Exception("Error getting candidate profiles");
    //return null;
  }
  
}*/

Future<(Iterable<ProfileData>, Iterable<ChatMessage>)?> getInitialMatchData() async {
  
  var response = await _request(
    (String authHeader) async {
      
      
      
      //HttpClientRequest request = await httpClient.get(root, port, "/matches");
      HttpClientRequest request = await httpClient.getUrl(Uri.parse("$rootUrl/matches"));
      request.headers.add("Authorization", authHeader);
      return await request.close();
    }
  );
  
  if (response != null && response.statusCode == 200) {
    String body = await response.getBody();
    print(body);
    //debugPrint(response.body);
    //debugPrint("${ProfileData.fromMapList(jsonDecode(response.body))}");
    try {
      var decoded = jsonDecode(body) as Map<String, dynamic>;
      return (
        ProfileData.extractAll(decoded["profiles"] as List),
        ChatMessage.extractAll(decoded["messages"]) // as List<Map<String, dynamic>>
      );
    } catch(err) {
      print("Error decoding matches $err");
      return null;
    }
    
    //return ProfileData.fromMapList(jsonDecode(body));
  } else {
    throw Exception("Error getting candidate profiles");
    //return null;
  }
  
}

/* WS */
Future<void> wsConnect() async {
  
  HttpClientResponse? response = await _request(
    (String authHeader) async {
      
      // very, shitty temporary hack
      Random r = Random();
      String key = base64.encode(List<int>.generate(8, (_) => r.nextInt(256)));
      
      //HttpClientRequest request = await httpClient.get(root, port, "/ws");
      HttpClientRequest request = await httpClient.getUrl(Uri.parse("$rootUrl/ws"));
      request.headers.add("Authorization", authHeader);
      request.headers.add("Connection", "upgrade");
      request.headers.add("Upgrade", "websocket");
      request.headers.add("Sec-WebSocket-Version", "13");
      request.headers.add("Sec-WebSocket-Key", key);
      return await request.close();
    }
  );
  
  if (response != null && response.statusCode == 101) {
    
    wsClose();
    
    WebSocket socket = (ws = WebSocket.fromUpgradedSocket(
      await response.detachSocket(),
      serverSide: false
    ));
    
    socket.listen(
      wsHandleData,
      onDone: wsHandleDone,
      onError: wsHandleError
    );
    
    print("WebSocket connection established!");
    wsOnConnect();
    
  } else {
    print("Invalid WebSocket upgrade response: ${response?.statusCode}");
  }
  
}
void wsClose() {
  ws?.close(1000, 'CLOSE_NORMAL');
}

void wsSendString(String data, { bool soft = false }) {
  
  if (ws != null) {
    ws!.add(data);
  } else if (!soft) {
    throw Exception("Attempted to send to websocket while disconnected");
  }
  
}
void wsSend(dynamic data, { bool soft = false }) {
  
  late String encoded;
  
  try {
    encoded = jsonEncode(data);
  } catch(err) {
    debugPrint("Error encoding message: $err");
    return;
  }
  
  wsSendString(encoded, soft: soft);
  
}
void wsSendImpression(String userID, bool liked, { bool soft = false }) {
  wsSend({
    "type": "impression",
    "toId": userID,
    "liked": liked
  }, soft: soft);
}
void wsSendChatMessage(String receiverID, String content, { bool soft = false }) {
  wsSend({
    "type": "chatMessage",
    "toId": receiverID,
    "content": content
  }, soft: soft);
}
void wsRequestQueueRefresh({ bool soft = false }) {
  wsSend({
    "type": "queueRefresh",
    "blacklist": profileQueue.map((profile) => profile.id).toList()
  }, soft: soft);
}

void wsOnConnect() {
  refreshProfileQueue();
}
void wsHandleData(dynamic data) {
  
  if (data is String) {
    wsHandleString(data);
  } else {
    throw Exception("Invalid WebSocket data received: $data");
  }
  
}
void wsHandleString(String data) {
  
  Map<String, dynamic> message;
  
  try {
    message = jsonDecode(data);
  } catch(err) {
    rethrow;
  }
  
  var _ = switch(message["type"]) {
    null => print("Invalid message: $message"),
    "like" => wsHandleLike(),
    "match" => wsHandleMatch(ProfileData.extract(message)),
    "chatMessage" => wsHandleChatMessage(extract(message["fromId"]), extract(message["messageId"]), extract(message["content"])),
    "queueRefresh" => wsHandleQueueRefresh(ProfileData.extractAll(message["profiles"])), 
    _ => print("Invalid message type: ${message["type"]}"),
  };
  
  print("WebSocket message received: $data");
  
}
void wsHandleLike() {
  print("New like!");
}
void wsHandleMatch(ProfileData profile) {
  print("New match! ${profile.id}");
  handleMatchData([ profile ]);
  //handleMatchData();
}
void wsHandleChatMessage(String senderId, String messageId, String messageContent) {
  //ChatMessage.extract
  print("New message! $senderId -> $messageId | $messageContent");
}
void wsHandleQueueRefresh(Iterable<ProfileData> profiles) {
  
  if (profiles.isEmpty) {
    return;
  }
  
  if (profileQueue.isEmpty) {
    profileQueue.addAll(profiles);
    nextProfileChanged.emit(profileQueue.first);
  } else {
    profileQueue.addAll(profiles);
  }
  
}

void wsHandleDone() {
  ws = null;
  print("WebSocket connection closed.");
}
void wsHandleError(dynamic error) {
  ws = null;
  throw Exception("WebSocket error: $error");
}

void handleLike(String profileID) {
  wsSendImpression(profileID, true);
}
void handleDislike(String profileID) {
  wsSendImpression(profileID, false);
}

extension on HttpClientResponse {
  
  Future<String> getBody() async {
    return await transform(utf8.decoder).join();
  }
  
}









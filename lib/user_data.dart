


import 'package:flutter/foundation.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/data.dart';

import 'utils.dart';

import 'package:age_calculator/age_calculator.dart';




class ProfilePhoto {
  
  static final _uuid = Uuid(
    goptions: GlobalOptions(CryptoRNG())
  );
  
  //Profile profile;
  final String profileID;
  final String photoID;
  Uint8List? data;
  
  String get path => "$profileID/$photoID";
  
  ProfilePhoto({ required this.profileID, required this.photoID, this.data });
  ProfilePhoto.create({ required String profileID, required Uint8List data }) :
    this(profileID: profileID, photoID: _uuid.v4(), data: data);
  
  //ProfilePhoto.create(Uint8List data) : this(id: _uuid.v4(), data: data);
  
  //ProfilePhoto clone() => ProfilePhoto(id: id, data: data);
  
}




const _fields = (
  
  id: "id",
  
  // Private
  latitude: "latitude",
  longitude: "longitude",
  birthDate: "birthDate",
  
  // Vitals
  name: "name",
  genderIdentity: "genderIdentity",
  pronouns: "pronouns",
  
  // Derived
  age: "age",
  
  // Derived Profile
  distance: "distance",
  
  // Profile
  bio: "bio",
  lookingFor: "lookingFor",
  
  interests: "interests",
  photos: "photos",
  
);

abstract class Profile {
  
  String get id;
  
  /* Derived */
  int? get age;
  int? get distance;
  
  /* Vitals */
  String? get name;
  String? get genderIdentity;
  String? get pronouns;
  
  /* Profile */
  String get bio;
  String get lookingFor;
  
  List<String> get interests;
  List<ProfilePhoto> get photos;
  
  static List<String> parseInterests(dynamic interests) {
    String string = (interests ?? "") as String;
    return string.isEmpty ? [] : string.split(", ");
  }
    
  static List<ProfilePhoto> parsePhotos(String profileID, dynamic photos) {
    String string = (photos ?? "") as String;
    return string.isEmpty ? [] : string.split(", ")
      .map((photoID) => ProfilePhoto(profileID: profileID, photoID: photoID))
      .toList();
  }
  
  //Profile({ required this.id });
  
}

class UserData extends Profile {
  
  static const maxPhotos = 6;
  
  static const choices = (
    
    interests: [
      "Scheming",
      "Mischief",
      "etc"
    ],
    
  );
  
  @override final String id;
  
  (double, double)? location;
  DateTime? birthDate;
  
  @override String name;
  @override String genderIdentity;
  @override String pronouns;
  
  @override String bio;
  @override String lookingFor;
  
  @override List<String> interests;
  @override List<ProfilePhoto> photos;
  
  
  
  double? get latitude => location?.$1;
  double? get longitude => location?.$2;
  
  @override int? get age {
    return birthDate == null ? 
      null : AgeCalculator.age(birthDate!).years;
  }
  @override int? get distance {
    return 0;
  }
  
  
  
  UserData({
    
    required this.id,
    
    this.location,
    this.birthDate,
    
    this.name = "",
    this.genderIdentity = "",
    this.pronouns = "",
    
    this.bio = "",
    this.lookingFor = "",
    
    this.interests = const [],
    this.photos = const []
    
  });
  
  factory UserData.fromMap(String id, Object? map) {
    
    try {
      
      if (map is! Map<String, Object?>) {
        throw Exception("Invalid map for ChatMessage.extract");
      } else {
        
        double? latitude = extractOrNull(map[_fields.latitude]);
        double? longitude = extractOrNull(map[_fields.longitude]);
        String? birthDate = extractOrNull(map[_fields.birthDate]);
        
        //print(Profile.parsePhotos(id, map[_fields.photos]));
        //print(map[_fields.photos]);
        
        return UserData(
          
          id: id,
          
          location: (latitude == null || longitude == null) ?
            null : (latitude, longitude),
          birthDate: birthDate == null ?
            null : DateTime.parse(birthDate),
            
          name: extractOr(map[_fields.name], ""),
          genderIdentity: extractOr(map[_fields.genderIdentity], ""),
          pronouns: extractOr(map[_fields.pronouns], ""),
          
          bio: extractOr(map[_fields.bio], ""),
          lookingFor: extractOr(map[_fields.lookingFor], ""),
          
          interests: Profile.parseInterests(map[_fields.interests]),
          photos: Profile.parsePhotos(id, map[_fields.photos])
          
        );
        
      }
    } catch(err) {
      debugPrint("Error decoding ChatMessage: $map");
      rethrow;
    }
    
  }
  
  Map<String, Object> toMap() {
    return {
      
      /* PRIVATE */
      _fields.latitude: latitude,
      _fields.longitude: longitude,
      _fields.birthDate: birthDate.toString(),
      
      /* VITALS */
      _fields.name: name,
      _fields.genderIdentity: genderIdentity,
      _fields.pronouns: pronouns,
      
      /* PROFILE */
      _fields.bio: bio,
      _fields.lookingFor: lookingFor,
      
      _fields.interests: interests.join(", "),
      _fields.photos: photos.map((photo) => photo.photoID).join(", ")
      
    }.withoutNulls();
    
  }
  Map<String, Object> deltaMap(UserData oldData) {
    return _delta(
      oldData: oldData.toMap(),
      newData: toMap()
    );
  }
  
  UserData clone() => UserData(
    
    id: id,
    
    location: location,
    birthDate: birthDate,
    
    name: name,
    genderIdentity: genderIdentity,
    pronouns: pronouns,
    
    bio: bio,
    lookingFor: lookingFor,
    
    interests: interests.toList(),
    photos: photos.toList()
    // intentionally passing around the same photo objects
    // loading photo data should be reflected everywhere
    
  );
  
  /*
  ProfileData profileData() =>
    ProfileData(
      
      id: id,
      
      /* DERIVED */
      age: age,
      
      /* VITALS */
      name: name,
      genderIdentity: genderIdentity,
      pronouns: pronouns,
      
      /* PROFILE */
      bio: bio,
      lookingFor: lookingFor,
      
      interests: interests,
      photos: photos,
      
    );
  */
  
  void newPhoto(Uint8List data) {
    if (photos.length < maxPhotos) {
      photos.add(ProfilePhoto.create(profileID: id, data: data));
    }
  }
  void deletePhoto(ProfilePhoto photo) {
    photos.remove(photo);
  }
  
  
  
}



class ProfileData extends Profile {
  
  @override final String id;
  
  @override String name;
  @override String genderIdentity;
  @override String pronouns;
  
  @override int? age;
  @override int? distance;
  
  @override String bio;
  @override String lookingFor;
  
  @override List<String> interests;
  @override List<ProfilePhoto> photos;
  
  
  ProfileData({
    
    required this.id,
    
    this.name = "",
    this.genderIdentity = "",
    this.pronouns = "",
    
    this.age,
    this.distance,
    
    this.bio = "",
    this.lookingFor = "",
    
    this.interests = const [],
    this.photos = const []
    
  });
  
  factory ProfileData.extract(Object? map) {
    
    try {
      if (map is! Map<String, Object?>) {
        throw Exception("Invalid map for ChatMessage.extract");
      } else {
        
        String id = extract(map[_fields.id]);
        
        return ProfileData(
          
          id: id,
          
          name: extractOr(map[_fields.name], ""),
          genderIdentity: extractOr(map[_fields.genderIdentity], ""),
          pronouns: extractOr(map[_fields.pronouns], ""),
          
          age: extractOrNull(map[_fields.age]),
          distance: extractOrNull(map[_fields.distance]),
          
          bio: extractOr(map[_fields.bio], ""),
          lookingFor: extractOr(map[_fields.lookingFor], ""),
          
          interests: Profile.parseInterests(map[_fields.interests]),
          photos: Profile.parsePhotos(id, map[_fields.photos])
          
        );
      }
    } catch(err) {
      debugPrint("Error decoding ChatMessage: $map");
      rethrow;
    }
    
  }
  
  // probably wants some type checking to avoid dart's classic silent errors
  static Iterable<ProfileData> extractAll(Object? list) {
    
    try {
      return extractAllCustom<ProfileData>(list, ProfileData.extract).toList();
    } catch(err) {
      print("Error decoding profile list: $list");
      return [];
    }
    
  }
  
  /*
  Map<String, Object> toMap() {
    
    return {
      
      _fields.name: name,
      //_fields.age: age, // don't upload age directly
      _fields.genderIdentity: genderIdentity,
      _fields.pronouns: pronouns,
      
      _fields.bio: bio,
      _fields.lookingFor: lookingFor,
      
      _fields.interests: interests,
      
      _fields.photos: photos.map((photo) => photo.id)
      
    }.withoutNulls(); //.withoutNulls(); // appease firebase
    
  }
  Map<String, Object> delta(ProfileData oldData) {
    
    return _delta(
      oldData: oldData.toMap(),
      newData: toMap()
    );
    
  }
  */
  
  /*
  ProfileData clone() => ProfileData(
    
    name: name,
    age: age,
    genderIdentity: genderIdentity,
    pronouns: pronouns,
    
    bio: bio,
    lookingFor: lookingFor,
    
    interests: interests.toList(),
    photos: photos.toList()
    
  );
  */
  
  
  
}

Map<String, Object> _delta({
  required Map<String, Object> newData,
  required Map<String, Object> oldData
}) {
  
  Map<String, Object> delta = {};
  
  
  bool equals(Object lhs, Object? rhs) {
    
    if (lhs is List && rhs is List) {
      return listEquals(lhs, rhs);
    } else {
      return lhs == rhs;
    }
    
  }
  
  for (var MapEntry(:key, :value) in newData.entries) {
    if (!equals(value, oldData[key])) {
      delta[key] = value;
    }
  }
  
  return delta;
  
}


class Match {
  
  //final messagesChanged = Signal<List<ChatMessage>>();
  
  ProfileData profileData;
  var messages = Observable<List<ChatMessage>>([]);
  
  Match(this.profileData);
  
  ChatMessage? getLatestMessage() => messages.data.lastOrNull;
  
  void addOldMessages(List<ChatMessage> newMessages) {
    messages.set([...newMessages, ...messages.data]);
  }
  void addNewMessages(List<ChatMessage> newMessages) {
    messages.data.addAll(newMessages);
    //messages.data
    //messages.data.sort((lhs, rhs) => lhs.timestamp.compareTo(rhs.timestamp));
    messages.update();
  }
  
}

class ChatMessage {
  
  static const _fields = (
    id: "id",
    userID: "user", // lower case d!
    content: "content",
    timestamp: "timestamp",
    outgoing: "outgoing"
  );
  
  final String id;
  final String userID; // refactor to omit?
  final bool outgoing;
  
  final DateTime timestamp;
  final String content;
  
  bool get isOutgoing => outgoing;
  bool get isIncoming => !outgoing;
  
  ChatMessage({
    required this.id,
    required this.userID,
    required this.content,
    required this.timestamp,
    required this.outgoing
  });
  /*
  factory ChatMessage.outgoing({ required String id, required String content, required DateTime timestamp }) =>
    ChatMessage(id, content, timestamp, true);
  factory ChatMessage.incoming({ required String id, required String content, required DateTime timestamp }) =>
    ChatMessage(id, content, timestamp, false);
  */
  
  factory ChatMessage.outgoing({ required String id, required String userID, required String content }) =>
    ChatMessage(id: id, userID: userID, content: content, timestamp: DateTime.now(), outgoing: true);
  
  factory ChatMessage.extract(Object? map) {
    
    try {
      if (map is! Map<String, Object?>) {
        throw Exception("Invalid map for ChatMessage.extract");
      } else {
        return ChatMessage(
          id: extract<String>(map[_fields.id]),
          userID: extract<String>(map[_fields.userID]),
          content: extractOr<String>(map[_fields.content], ""),
          timestamp: DateTime.parse(extractOr(map[_fields.timestamp], "")),
          outgoing: extract<bool>(map[_fields.outgoing])
        );
      }
    } catch(err) {
      debugPrint("Error decoding ChatMessage: $map");
      rethrow;
    }
    
  }
  static Iterable<ChatMessage> extractAll(Object? list) { //List<Map<String, dynamic>> maps) {
    
    try {
      return extractAllCustom<ChatMessage>(list, ChatMessage.extract).toList();
    } catch(err) {
      print("Error decoding ChatMessage list: $list");
      return [];
    }
    
    //maps.map((map) => ChatMessage.fromMap(map)).toList();
    
    
  }
  
  
  
}



/*
class UserSettings {
  
  (double, double)? location;
  DateTime? birthDate;
  
  double? get latitude => location?.$1;
  double? get longitude => location?.$2;
  
  UserSettings({
    required this.location,
    required this.birthDate
  });
  
  factory UserSettings.fromMap(Map<String, dynamic> map) {
    
    var latitude = map[_fields.latitude] as double?;
    var longitude = map[_fields.longitude] as double?;
    var birthDate = map[_fields.birthDate] as String?;
    
    return UserSettings(
      
      location: (latitude == null || longitude == null) ?
        null : (latitude, longitude),
      birthDate: birthDate == null ?
        null : DateTime.parse(birthDate)
      
    );
    
  }
  
  Map<String, Object> toMap() {
    return {
      _fields.latitude: latitude,
      _fields.longitude: longitude,
      _fields.birthDate: birthDate.toString()
    }.withoutNulls();
  }
  
}
*/




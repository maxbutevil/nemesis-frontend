

import "package:flutter/material.dart";
//import "package:image_picker/image_picker.dart";

//import '/utils/globals.dart';
//import '/utils/utils.dart';

//import '/firebase.dart' as fb;
//import '/classes/profile.dart';

//import '/user_data.dart';

import '/widgets/setting.dart';
import '/widgets/profile_view.dart';
import '/client.dart' as client;


class ProfilePage extends StatefulWidget {
  
  const ProfilePage({ super.key });
  
  @override ProfilePageState createState() => ProfilePageState();
  
}

//LocationData? _locationData;

class ProfilePageState extends State<ProfilePage> {
  
  ProfilePageState();
  
  final Future<UserData?> _getData = client.getUserData();
  //Profile? profile;
  
  UserData? data;
  UserData? oldData;
  
  Widget buildProfileViewPage() {
    
    return Scaffold(
      appBar: AppBar(
        /*leading: BackButton(onPressed: () {
          //navigatorKey.currentState?.pop();
        }),*/
        title: const Text("Your Profile")
      ),
      body: ProfileView(data!)
      
      /*Padding(
        padding: const EdgeInsets.all(10.0),
        child: ProfileView(fb.profile!)
      )*/
    );
    
  }
  
  Widget buildProfilePhoto() {
    
    var photos = data!.photos;
    
    if (photos.isEmpty) {
      
      return Image.asset(
        "guy.png",
        fit: BoxFit.fitWidth
      );
      
    } else {
      
      // this is so ass
      return FutureBuilder(
        future: client.getPhotoData(photos[0]),
        builder: (context, snapshot) {
          
          var photoData = snapshot.data;
          
          if (photoData == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Image.memory(
            photoData,
            fit: BoxFit.fitWidth
          );
          
        }
      );
      
    }
    
  }
  Widget buildProfileViewButton() {
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(60.0, 60.0, 60.0, 30.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: GestureDetector(
          onTap: () {
            
            if (data != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => buildProfileViewPage()
                )
              );
            }
            
          },
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: FutureBuilder(
              future: _getData,
              builder: (context, snapshot) {
                
                print(snapshot.data);
                
                var profile = snapshot.data;
                
                if (profile == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                return buildProfilePhoto();
                
              }
            ),
          )
        )
      )
    );
    
  }
  Widget buildSettingList(BuildContext context) {
    
    return FutureBuilder(
      future: _getData,
      builder: (context, snapshot) {
        
        if (snapshot.data == null) {
          // 
          return const Center(
            child: CircularProgressIndicator()
          );
        }
        
        data ??= snapshot.data!;
        oldData ??= data?.clone();
        
        return SettingList([
          buildProfileViewButton(),
          PhotoSelectSetting(
            "Photos",
            SetGet(
              (val) => data!.photos = val,
              () => data!.photos
            ),
          ),
          Setting.string(
            "Name",
            SetGet(
              (val) => data!.name = val,
              () => data!.name
            )
          ),
          Setting.string(
            "Bio",
            SetGet(
              (val) => data!.bio = val,
              () => data!.bio
            )
          ), // bio
          Setting.string(
            "Looking For",
            SetGet(
              (val) => data!.lookingFor = val,
              () => data!.lookingFor
            )
          ),
          Setting.tagSelect(
            "Interests",
            SetGet(
              (val) => data!.interests = val,
              () => data!.interests
            ),
            UserData.choices.interests
          )
        ]);
        
      }
    );
    
  }
  
  @override Widget build(BuildContext context) {
    
    return buildSettingList(context);
    
  }
  
  @override
  void dispose() {
    
    if (data != null) {
      client.saveUserData(oldData: oldData!);
    }
    
    super.dispose();
    
  }
  
}



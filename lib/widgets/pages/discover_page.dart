


import "package:flutter/material.dart";

import '/utils.dart';
import "../profile_view.dart";
import "/client.dart" as client;

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({ super.key });
  @override createState() => DiscoverPageState();
}

class DiscoverPageState extends State<DiscoverPage> {
  
  //Future<ProfileData?> _getProfileData = client.peekNextProfile();
  ProfileData? get profileData => client.profileQueue.firstOrNull;
  
  DiscoverPageState();
  
  void nextProfile() {
    setState(() {
      client.toNextProfile();
      //profileData = null;
      //_getProfileData = client.toNextProfile();
    });
  }
  void dislikeProfile() {
    if (profileData != null) {
      client.handleDislike(profileData!.id);
      nextProfile();
    }
  }
  void likeProfile() {
    if (profileData != null) {
      client.handleLike(profileData!.id);
      nextProfile();
    }
  }
  
  @override initState() {
    super.initState();
    client.refreshProfileQueue();
  }
  @override build(BuildContext context) {
    
    return Stack(
      fit: StackFit.expand,
      children: [
        buildNextMatch(),
        Positioned(
          left: 10,
          bottom: 10,
          child: FloatingActionButton(
            elevation: 0.0,
            onPressed: dislikeProfile,
            child: const Icon(Icons.close)
          )
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: FloatingActionButton(
            elevation: 0.0,
            onPressed: likeProfile,
            child: const Icon(Icons.done)
          )
        ),
      ]
    );
    
  }
  Widget buildNextMatch() {
    
    return SignalBuilder(
      signal: client.nextProfileChanged,
      builder: (context, _) {
        
        if (profileData == null) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return ProfileView(profileData!);
        }
        
      }
    );
    
  }
  
}





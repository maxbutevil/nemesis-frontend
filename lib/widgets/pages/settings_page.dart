

import "package:flutter/material.dart";
import '../setting.dart';
import '/client.dart' as client;
import '../../user_data.dart';

class SettingsPage extends StatefulWidget {
  
  const SettingsPage({ super.key });
  
  @override
  SettingsPageState createState() => SettingsPageState();
  
}

class SettingsPageState extends State<SettingsPage> {
  
  SettingsPageState();
  
  final Future<UserData?> _getData = client.getUserData();
  UserData? data;
  UserData? oldData;
  
  @override
  Widget build(BuildContext context) {
    
    return FutureBuilder(
      future: _getData,
      builder: (context, snapshot) {
        
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        data ??= snapshot.data!;
        oldData ??= data?.clone();
        
        return SettingList([
          Setting.location(
            "location (may lag a bit)",
            SetGet(
              (val) => data!.location = val,
              () => data!.location
            )
          ),
          ListTile(
            title: const Text("Sign Out"),
            onTap: () {
              client.googleSignOut();
            }
          )
        ]);
        
      }
    );
    
    
    
  }
  
  @override
  void dispose() {
    
    if (data != null) {
      client.saveUserData(oldData: oldData!);
    }
    
    super.dispose();
    
  }
  
}



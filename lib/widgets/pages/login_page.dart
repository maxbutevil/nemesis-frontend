



//import '/utils/globals.dart';
//import '/utils/routes.dart';

//import '/utils/firebase_utils.dart';
import "/client.dart" as client;
import "package:flutter/material.dart";

class LoginPage extends StatefulWidget {
  
  const LoginPage({ super.key });
  
  @override
  LoginPageState createState() => LoginPageState();
  
}

class LoginPageState extends State<LoginPage> {
  
  LoginPageState();
  
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(title: const Text("Log In")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => client.googleSignIn(),
          child: const Text("Sign In")
        )
      )
    );
    
    
    
  }
  
}





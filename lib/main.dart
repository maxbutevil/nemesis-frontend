

// flutter emulators --launch pixel
//import "package:flutter/foundation.dart";


//import "indices/firebase.dart";
import "package:flutter/material.dart";
//import "package:firebase_core/firebase_core.dart";

//import "data/profile.dart";
//import "utils/firebase_utils.dart";
import "/utils.dart";

import 'widgets/pages/login_page.dart';
//import 'widgets/pages/register_page.dart';
import 'widgets/pages/settings_page.dart';
import 'widgets/pages/profile_page.dart';
import 'widgets/pages/discover_page.dart';
import 'widgets/pages/match_list_page.dart';

import "client.dart" as client;

//GlobalKey postListKey = GlobalKey(debugLabel: "Post List");

Future main() async {
  
  
  
  WidgetsFlutterBinding.ensureInitialized();
  
  await client.initialize();
  
  runApp(App());
  
  //client.getSelfProfile();
  
}




class App extends StatelessWidget {
  
  static final theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    useMaterial3: true,
  );
  
  App({ super.key }) {
  
    client.onAuthStateChanges((signedIn) {
      
      if (signedIn) {
        //print("Signed in!! ${user.displayName} | ${user.uid}");
        print("Signed in!");
        Globals.navigatorKey.currentState?.pushReplacementNamed(Globals.routes.home);
        //client.getSelfProfile();
      } else {
        print("Signed out / failed to sign in.");
        Globals.navigatorKey.currentState?.pushReplacementNamed(Globals.routes.login);
      }
      
    });
      
  }
  
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      
      theme: theme,
      
      navigatorKey: Globals.navigatorKey,
      
      initialRoute: client.isSignedIn() ? Globals.routes.home : Globals.routes.login,
      onGenerateRoute: useRouteMap({
        Globals.routes.login: (ctx, arg) => const LoginPage(),
        Globals.routes.home: (ctx, arg) => Home()
      })
      
    );
    
  }
}

class Home extends StatelessWidget {
  
  Home({ super.key });  

  static const initialPage = 1;
  static final pageRoutes = [
    Globals.routes.pages.settings,
    Globals.routes.pages.profile,
    Globals.routes.pages.match,
    Globals.routes.pages.chat
  ];
  
  final _navigatorKey = GlobalKey<NavigatorState>();
  //final _navigationBarKey = GlobalKey();
  
  NavigatorState get navigatorState { return _navigatorKey.currentState!; }
  
  Widget buildNavigator() {
    return Navigator(
      key: _navigatorKey,
      initialRoute: pageRoutes[initialPage],
      onGenerateRoute: useRouteMap({
        Globals.routes.pages.settings: (ctx, arg) => const SettingsPage(),
        Globals.routes.pages.profile:  (ctx, arg) => const ProfilePage(),
        Globals.routes.pages.match:    (ctx, arg) => const DiscoverPage(),
        Globals.routes.pages.chat:     (ctx, arg) => const MatchListPage(),
      })
    );
  }
  @override Widget build(BuildContext context) {
    
    return Scaffold(
      body: buildNavigator(),
      bottomNavigationBar: HomeNavigationBar(
        initialIndex: initialPage,
        onDestinationSelected: (index) {
          navigatorState.pushReplacementNamed(pageRoutes[index]);
        }
      )
    );
    
  }
  
}

class HomeNavigationBar extends StatefulWidget {
  
  final int initialIndex;
  final void Function(int) onDestinationSelected;
  
  HomeNavigationBar({ required this.initialIndex, required this.onDestinationSelected }) : super(key: GlobalKey());
  @override State<HomeNavigationBar> createState() => HomeNavigationBarState();
  
}

class HomeNavigationBarState extends State<HomeNavigationBar> {
  
  int selectedIndex = Home.initialPage;
  
  HomeNavigationBarState();
  
  @override build(BuildContext context) {
    
    return NavigationBar(
      //key: _navigationBarKey,
      selectedIndex: selectedIndex, // initialIndex,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.settings_applications), label: "Settings"),
        NavigationDestination(icon: Icon(Icons.account_box), label: "Profile"),
        NavigationDestination(icon: Icon(Icons.add_box), label: "Discover"),
        NavigationDestination(icon: Icon(Icons.chat), label: "Matches"),
      ],
      onDestinationSelected: (index) {
        
        if (selectedIndex == index) {
          return;
        }
        
        setState(() {
          selectedIndex = index; // not sure that this should be in here
          widget.onDestinationSelected(index); // not sure about this either
        });
        
      }
      
    );
  
  }
  
  
}


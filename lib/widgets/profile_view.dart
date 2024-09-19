


import "package:flutter/material.dart";
//import "package:cloud_firestore/cloud_firestore.dart";


import 'tag.dart';

import '/utils.dart';

import '/client.dart' as client;

import '/user_data.dart';
export '/user_data.dart';


class ProfileView extends StatefulWidget {
  
  final Profile profile;
  
  const ProfileView(this.profile, { super.key });
  
  @override createState() => ProfileViewState();
  
}


class ProfileViewState extends State<ProfileView> {
  
  //final DocumentReference<Profile> ref;
  Profile get profile => widget.profile;
  
  //const ProfileView(this.profile, { super.key }); // : super(key: ValueKey(ref.id));
  //ProfileView.fromDoc();
  
  @override
  Widget build(BuildContext context) {
    
    return ListView(
      
      padding: const EdgeInsets.all(6.0),
      shrinkWrap: true,
      
      children: [
        buildPrimaryCard(context),
        //buildImageCard(Image.asset("guy.png")),
        buildPhotoCard(profile.photos.elementAtOrNull(1)),
        buildSecondaryCard(context),
        buildPhotoCard(profile.photos.elementAtOrNull(2))
      ].nonNulls.toList()
      
    );
    
  }
  Widget? buildPhoto(ProfilePhoto? photo) {
    
    if (photo == null) {
      return null;
    }
    return FutureBuilder(
      /*
      future: Future.delayed(
        const Duration(seconds: 1),
        () => fb.storage.getPhotoData(profile.id, photo)
      ),
      */
      future: client.getPhotoData(photo),
      builder: (_, snapshot) {
        
        return AspectRatio(
          aspectRatio: Globals.profilePhotoAspectRatio,
          child: snapshot.hasData ?
            Image.memory(snapshot.data!, fit: BoxFit.fitWidth) :
            const Center(child: CircularProgressIndicator())
        );
        
      }
    );
    
  }
  Widget? buildPhotoCard(ProfilePhoto? photo) {
    return buildCard(buildPhoto(photo));
  }
  
  Widget? buildPrimaryCard(BuildContext context) {
    
    return buildColumnCard([
      //Image.asset("guy.png"),
      buildPhoto(profile.photos.elementAtOrNull(0)),
      buildPaddedColumn([
        buildHeader(),
        buildTagList(profile.interests),
        profile.bio.isEmpty ? null : Text(profile.bio)
      ]),
    ]);
    
  }
  Widget buildHeader() {
    
    var children = <InlineSpan>[
      TextSpan(
        text: profile.name,
        style: const TextStyle(fontWeight: FontWeight.bold)
      ),
    ];
    
    if (profile.age != null) {
      children.addAll([
        const WidgetSpan(child: SizedBox(width: 6.0)),
        TextSpan(
          text: profile.age.toString(),
        )
      ]);
    }
    
    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.titleLarge,
        children: children
      )
      
    );
    
  }
  
  Widget? buildSecondaryCard(BuildContext context) {
    
    return buildCard(
      buildPaddedColumn([
        buildSubsection("Looking For", profile.lookingFor)
      ])
    );
    
  }
  Widget? buildSubsection(String header, String content) {
    
    if (content.isEmpty) {
      return null;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          header,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(content)
      ]
    );
    
  }
  
  Widget? buildPaddedColumn(List<Widget?> children, { padding = const EdgeInsets.all(6.0) }) {
    
    List<Widget> nonNullChildren = children.nonNulls.toList();
    
    if (nonNullChildren.isEmpty) {
      return null;
    }
    
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: nonNullChildren
      )
    );
  }
  Widget? buildColumnCard(List<Widget?> children) {
    return buildCard(Column(children: children.nonNulls.toList()));
  }
  
  Widget? buildCard(Widget? child) {
    
    if (child == null) {
      return null;
    }
    
    return Card(
      clipBehavior: Clip.hardEdge,
      child: child
    );
    
  }
  
  Widget? buildTagList(List<String> content) {
    return content.isEmpty ? null : Tag.list(
      content.map((String c) => Tag(c))
    );
  }
  

  
}










import "package:flutter/material.dart";
//import "package:nemesis/firebase.dart";

import "../widgets/tag.dart";

import "../location.dart";
export "../location.dart";

//import "/utils/firebase_utils.dart";
import '/client.dart' as client;
import '/user_data.dart';

import 'package:image_picker/image_picker.dart';
//import "/firebase.dart" as fb;
//import "/utils/utils.dart";

import '/utils.dart';

import 'dart:typed_data';



class SetGet<T> {
  
  final Function(T) set;
  final T Function() get;
  
  const SetGet(this.set, this.get);
  
}

abstract class Setting<T> extends StatefulWidget {
  
  final String name;
  final SetGet<T> _value;
  
  const Setting(this.name, SetGet<T> value) : _value = value;
  @override createState() => SettingState();
  
  T get value { return _value.get(); }
  set value(T newValue) { _value.set(newValue); }
  
  
  //String getTileTitle() => name;
  //String getTileSubtitle() => value.toString();
  
  Widget buildTileTitle() => Text(name);
  Widget buildTileSubtitle() => Text(value.toString());
  //SettingTile<T> buildTile() => SettingTile(this);
  SettingPage<T> buildPage() => SettingPage(this);
  Widget buildForm();
  
  Future<void> pushPage(/* BuildContext context */) async {
    
    await Globals.navigatorState?.push( // global navigator, use Navigator.of() for local
      MaterialPageRoute(builder: (ctx) => buildPage())
    );
    
  }
  
  static string(String name, SetGet<String> value) => StringSetting(name, value);
  static location(String name, SetGet<(double, double)?> value) => LocationSetting(name, value);
  static tagSelect(String name, SetGet<List<String>> value, List<String> choices, { int maxChoiceCount = 5 })
    => TagSelectSetting(name, value, choices, maxChoiceCount: maxChoiceCount);
  //static photo(String name, SetGet<String> value, {}) => PhotoSelectSetting(name, value, minCount: minCount, maxCount: maxCount)
  
}
class SettingState<T> extends State<Setting> {
  
  SettingState();
  
  @override build(BuildContext context) {
    
    return ListTile(
      //title: Text(widget.setting.getTileTitle()),
      //subtitle: Text(widget.setting.getTileSubtitle()),
      title: widget.buildTileTitle(),
      subtitle: widget.buildTileSubtitle(),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => widget.pushPage().then((_) {
        setState(() {}); // update tile content after page is closed
      })
    );
    
  }
  
}


class SettingList extends StatelessWidget {
  
  final List<Widget> children;
  const SettingList(this.children, { super.key });
  
  @override Widget build(BuildContext context) {
    
    const divider = Divider(
      height: 2.0,
      thickness: 2.0,
      indent: 10.0,
      endIndent: 10.0
    );
    
    return ListView.separated(
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
      separatorBuilder: (_, i) => divider,
    );
    
  }
  
}



class SettingPage<T> extends StatelessWidget {
  
  final Setting setting;
  
  const SettingPage(this.setting, { super.key });
  
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        /*leading: BackButton(onPressed: () {
          //navigatorKey.currentState?.pop();
        }),*/
        title: Text(setting.name)
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: setting.buildForm()
      )
    );
    
  }
  
}


class StringSetting extends Setting<String> {
  
  final int maxLength;
  const StringSetting(super.name, super.value, { this.maxLength = 240 });
  
  @override buildForm() {
    
    return TextFormField(
      
      maxLength: maxLength,
      
      initialValue: value,
      onChanged: (content) => value = content
      
    );
  }
  
}

class LocationSetting extends Setting<(double, double)?> { // extends Setting<LocationData?> {
  
  LocationSetting(super.name, super.value);
  
  @override buildTileSubtitle() {
    return Text(
      value == null ? "unknown" : "${value!.$1}, ${value!.$2}"
    );
  }
  
  @override buildForm() {
    
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          // scuffed
          //value = await getLocation();
          
          final locationData = await getLocation();
          
          if (locationData != null) {
            value = (locationData.latitude!, locationData.longitude!);
          }
          
        },
        child: const Text("Update Location")
      )
    );
    
  }
  
}

class TagSelectSetting extends Setting<List<String>> {
  
  final List<String> choices;
  final int? maxChoiceCount;
  
  //List<String> selected = [];
  
  List<String> get selected => value;
  
  TagSelectSetting(super.name, super.value, this.choices, { this.maxChoiceCount });
  
  bool get canChooseMore => maxChoiceCount == null || selected.length < maxChoiceCount!;
  
  @override buildForm() => TagSelectSettingForm(this);
  @override buildTileSubtitle() => Text(
    value.isEmpty ? "None" : value.join(", ")
  );
  
}
class TagSelectSettingForm extends StatefulWidget {
  
  final TagSelectSetting setting;
  const TagSelectSettingForm(this.setting, { super.key });
  @override createState() => TagSelectSettingFormState();
  
}
class TagSelectSettingFormState extends State<TagSelectSettingForm> {
  
  List<String> get choices => widget.setting.choices;
  List<String> get selected => widget.setting.selected;
  
  @override build(BuildContext context) {
    
    final bool canChooseMore = widget.setting.canChooseMore;
    
    return Tag.list(
      choices.map((choice) {
        
        final bool isSelected = selected.contains(choice);
        
        return Tag(
          choice,
          initialToggleable: isSelected || canChooseMore,
          initialSelected: isSelected,
          onToggle: (newSelected) {
            
            if (newSelected) {
              selected.add(choice);
            } else {
              selected.remove(choice);
            }
            
          }
        );
        
      })
    );
  }
  
}

class PhotoSelectSetting extends Setting<List<ProfilePhoto>> {
  
  final int minCount;
  final int maxCount;
  
  @override buildTileSubtitle() => Text("${value.length}/$maxCount photos");
  
  PhotoSelectSetting(String name, SetGet<List<ProfilePhoto>> value, {
    this.minCount = 4,
    this.maxCount = 6
  }) : super(name, value);
  
  @override buildForm() => PhotoSelectSettingForm(this);
  
}
class PhotoSelectSettingForm extends StatefulWidget {
  
  final PhotoSelectSetting setting;
  const PhotoSelectSettingForm(this.setting, { super.key });
  @override createState() => PhotoSelectSettingFormState();
  
}
class PhotoSelectSettingFormState extends State<PhotoSelectSettingForm> {
  
  
  final _imagePicker = ImagePicker();
  List<ProfilePhoto> get value => widget.setting.value;
  
  PhotoSelectSettingFormState();
  
  
  void _addPhotos() async {
    
    List<XFile> images = await _imagePicker.pickMultiImage(imageQuality: 10);
    List<Uint8List> imageData = await Future.wait(
      images.map(
        (image) => image.readAsBytes()
      )
    );
    
    //print(imageData);
    
    setState(() {
      for (Uint8List data in imageData) {
        value.add(ProfilePhoto.create(profileID: client.getUserId()!, data: data));
      }
    });
    
    //print(images);
    
    //await fb.storage.newPhotos(imageData);
    
    //widget.setting.value = fb.profile!.data.photos;
    
  }
  void _deletePhoto(ProfilePhoto photo) {
    setState(() => value.remove(photo));
  }
  /*
  void _replacePhoto() {
    //_imagePicker.pickImage();
  }
  */
  Widget buildPhoto(ProfilePhoto? photo) {
    
    Widget body;
    
    if (photo == null) {
      
      body = InkWell(
        onTap: () => _addPhotos(),
        child: const Center(child: Icon(Icons.add))
      );
      
    } else {
      
      body = FutureBuilder(
        future: client.getPhotoData(photo),
        builder: (_, snapshot) {
          
          Widget child;
          
          if (!snapshot.hasData) {
            child = const Center(
              child: CircularProgressIndicator()
            );
          } else {
            child = Image.memory(photo.data!);
          }
          
          return GestureDetector(
            onDoubleTap: () => _deletePhoto(photo),
            child: child,
          );
          
        }
      );
      
    }
    
    return Card(
      clipBehavior: Clip.hardEdge,
      child: body,
    );
    
  }
  List<Widget> buildPhotos(List<ProfilePhoto> photos) {
    
    List<Widget> widgets = [];
    
    for (ProfilePhoto photo in photos) {
      widgets.add(buildPhoto(photo));
    }
    
    for (int i = 0; i < widget.setting.maxCount - photos.length; i++) {
      widgets.add(buildPhoto(null));
    }
    
    return widgets;
    
  }
  
  @override build(BuildContext context) {
    
    return Column(
      
      children: [
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
          childAspectRatio: 0.8,
          shrinkWrap: true,
          children: buildPhotos(widget.setting.value)
          /*[
            buildPhoto(null),
            buildPhoto(null),
            buildPhoto(null),
            buildPhoto(null),
            buildPhoto(null),
            buildPhoto(null),
          ],*/
          
        )
      ]
    );
    
  }
  
}



/*
extension on State<SettingPage> {
  
}
*/

/*
class SettingPage<T> extends StatefulWidget {
  
  final Setting setting;
  const SettingPage(this.setting, { super.key });
  @override createState() => SettingPageState<T>();
  
}

class SettingPageState<T> extends State<SettingPage<T>> {
  
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setting.name)
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: widget.setting.buildForm()
      ),
    );
    
  }
  
}
*/



import "package:location/location.dart";
export "package:location/location.dart";

final _location = Location();

Future<LocationData?> getLocation() async {
  
  bool serviceEnabled = await _location.serviceEnabled();
  
  if (!serviceEnabled) {
    serviceEnabled = await _location.requestService();
    if (!serviceEnabled) return null;
  }
  
  PermissionStatus status = await _location.hasPermission();
  
  // Do something with PermissionStatus.grantedLimited
  if (status != PermissionStatus.granted) {
    status = await _location.requestPermission();
    if (status != PermissionStatus.granted) return null;
  }
  
  return await _location.getLocation();
  
}





